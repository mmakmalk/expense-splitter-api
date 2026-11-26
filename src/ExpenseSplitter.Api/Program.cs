var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHealthChecks();

var app = builder.Build();

// "Is the API alive?" Answers 200 "Healthy". Used by us, Docker and the tests.
app.MapHealthChecks("/health");

app.Run();

// Lets integration tests start the app with WebApplicationFactory<Program>.
public partial class Program;
