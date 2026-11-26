using Npgsql;

namespace ExpenseSplitter.Api.IntegrationTests.Infrastructure;

/// <summary>Checks the test infrastructure itself: ResetDatabaseAsync really empties the tables.</summary>
[Collection(ApiCollection.Name)]
public class DatabaseResetTests(ApiFactory api) : IntegrationTest(api)
{
    [Fact]
    public async Task Reset_removes_all_rows_but_keeps_tables()
    {
        await ExecuteAsync("CREATE TABLE IF NOT EXISTS reset_probe (id int PRIMARY KEY)");
        await ExecuteAsync("INSERT INTO reset_probe VALUES (1), (2)");
        Assert.Equal(2L, await ScalarAsync("SELECT count(*) FROM reset_probe"));

        await Api.ResetDatabaseAsync();

        Assert.Equal(0L, await ScalarAsync("SELECT count(*) FROM reset_probe"));
    }

    private async Task ExecuteAsync(string sql)
    {
        await using var connection = new NpgsqlConnection(Api.ConnectionString);
        await connection.OpenAsync();
        await using var command = new NpgsqlCommand(sql, connection);
        await command.ExecuteNonQueryAsync();
    }

    private async Task<object?> ScalarAsync(string sql)
    {
        await using var connection = new NpgsqlConnection(Api.ConnectionString);
        await connection.OpenAsync();
        await using var command = new NpgsqlCommand(sql, connection);
        return await command.ExecuteScalarAsync();
    }
}
