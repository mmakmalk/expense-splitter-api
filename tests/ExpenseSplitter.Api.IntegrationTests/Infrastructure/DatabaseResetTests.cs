using Npgsql;

namespace ExpenseSplitter.Api.IntegrationTests.Infrastructure;

/// <summary>Checks the test infrastructure itself: ResetDatabaseAsync really empties the tables.</summary>
[Collection(ApiCollection.Name)]
public class DatabaseResetTests(ApiFactory api) : IntegrationTest(api)
{
    [Fact]
    public async Task Reset_removes_all_rows_and_restarts_ids()
    {
        await ExecuteAsync("CREATE TABLE reset_probe (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name text)");
        try
        {
            await ExecuteAsync("INSERT INTO reset_probe (name) VALUES ('a'), ('b')");
            Assert.Equal(2L, await ScalarAsync("SELECT count(*) FROM reset_probe"));

            await Api.ResetDatabaseAsync();

            Assert.Equal(0L, await ScalarAsync("SELECT count(*) FROM reset_probe"));
            Assert.Equal(1, await ScalarAsync("INSERT INTO reset_probe (name) VALUES ('c') RETURNING id"));
        }
        finally
        {
            // The database is shared by all tests: leave no extra table behind.
            await ExecuteAsync("DROP TABLE IF EXISTS reset_probe");
        }
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
