namespace ExpenseSplitter.Api.IntegrationTests.Infrastructure;

/// <summary>
/// All integration test classes share one ApiFactory (one database container).
/// xUnit runs classes in the same collection one after another, so tests never clean the database under each other.
/// </summary>
[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<ApiFactory>
{
    public const string Name = "Api";
}

/// <summary>
/// Base class for integration tests: gives an HttpClient and starts each test with an empty database.
/// Usage: <c>[Collection(ApiCollection.Name)] public class GroupsTests(ApiFactory api) : IntegrationTest(api)</c>
/// </summary>
public abstract class IntegrationTest(ApiFactory api) : IAsyncLifetime
{
    protected ApiFactory Api { get; } = api;

    protected HttpClient Client { get; } = api.CreateClient();

    public Task InitializeAsync() => Api.ResetDatabaseAsync();

    public Task DisposeAsync()
    {
        Client.Dispose();
        return Task.CompletedTask;
    }
}
