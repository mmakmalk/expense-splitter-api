# Stage 1: build the app with the full .NET SDK.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy only project files first, so `restore` is cached until dependencies change.
COPY global.json Directory.Build.props ExpenseSplitter.slnx ./
COPY src/ExpenseSplitter.Api/ExpenseSplitter.Api.csproj src/ExpenseSplitter.Api/
COPY src/ExpenseSplitter.Domain/ExpenseSplitter.Domain.csproj src/ExpenseSplitter.Domain/
RUN dotnet restore src/ExpenseSplitter.Api/ExpenseSplitter.Api.csproj

COPY src/ src/
RUN dotnet publish src/ExpenseSplitter.Api/ExpenseSplitter.Api.csproj -c Release -o /app --no-restore

# Stage 2: run it on the small runtime-only image (no SDK, no source code).
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .

# Run as the image's built-in non-root user.
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "ExpenseSplitter.Api.dll"]
