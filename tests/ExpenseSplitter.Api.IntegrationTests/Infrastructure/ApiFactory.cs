using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Npgsql;
using Respawn;
using Testcontainers.PostgreSql;

namespace ExpenseSplitter.Api.IntegrationTests.Infrastructure;

/// <summary>
/// Starts ONE PostgreSQL container for the whole test run and the API in memory, pointed at it.
/// Between tests the database is cleaned with Respawn (ADR-0005).
/// </summary>
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    // Same major version as compose.yaml, so tests run against what we deploy.
    private readonly PostgreSqlContainer _db = new PostgreSqlBuilder("postgres:18-alpine").Build();

    public string ConnectionString => _db.GetConnectionString();

    public async Task InitializeAsync()
    {
        await _db.StartAsync();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Same key the app reads in Docker (ConnectionStrings__Default), now pointing at the test container.
        builder.UseSetting("ConnectionStrings:Default", ConnectionString);
    }

    /// <summary>Deletes all rows from all tables, so every test starts from an empty database.</summary>
    public async Task ResetDatabaseAsync()
    {
        await using var connection = new NpgsqlConnection(ConnectionString);
        await connection.OpenAsync();

        // No tables yet (e.g. before the first migration): nothing to clean.
        // Respawn would throw "No tables found".
        if (!await HasTablesToResetAsync(connection))
        {
            return;
        }

        // Built fresh every time (a few ms): reads the current table list, so tables added later are never missed.
        var respawner = await Respawner.CreateAsync(connection, new RespawnerOptions
        {
            DbAdapter = DbAdapter.Postgres,
            SchemasToInclude = ["public"],
            // EF Core migration history must survive, or the schema would be "forgotten".
            TablesToIgnore = ["__EFMigrationsHistory"],
        });

        await respawner.ResetAsync(connection);
    }

    private static async Task<bool> HasTablesToResetAsync(NpgsqlConnection connection)
    {
        await using var command = new NpgsqlCommand(
            """
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = 'public'
                  AND table_type = 'BASE TABLE'
                  AND table_name <> '__EFMigrationsHistory')
            """,
            connection);
        return (bool)(await command.ExecuteScalarAsync())!;
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await _db.DisposeAsync();
        await base.DisposeAsync();
    }
}
