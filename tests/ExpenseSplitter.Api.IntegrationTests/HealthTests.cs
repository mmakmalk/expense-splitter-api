using System.Net;
using ExpenseSplitter.Api.IntegrationTests.Infrastructure;
using Npgsql;

namespace ExpenseSplitter.Api.IntegrationTests;

[Collection(ApiCollection.Name)]
public class HealthTests(ApiFactory api) : IntegrationTest(api)
{
    [Fact]
    public async Task Health_returns_200_Healthy()
    {
        var response = await Client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Test_database_is_reachable()
    {
        await using var connection = new NpgsqlConnection(Api.ConnectionString);
        await connection.OpenAsync();
        await using var command = new NpgsqlCommand("SELECT 1", connection);

        Assert.Equal(1, await command.ExecuteScalarAsync());
    }
}
