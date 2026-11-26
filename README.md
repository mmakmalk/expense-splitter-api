# Expense Splitter API

API do dzielenia wspólnych wydatków w grupie (np. na wyjeździe): kto zapłacił, ile i kto komu ile oddaje.

**Stack:** ASP.NET Core (.NET 10, Minimal APIs) · PostgreSQL · EF Core · JWT · Docker Compose · Testcontainers

> Projekt w budowie. Decyzje architektoniczne są w [`docs/adr/`](docs/adr/).

## Uruchomienie

**Wymagania:** .NET 10 SDK, Docker Desktop.

### Przez Docker (API + baza)
```bash
cp .env.example .env      # potem ustaw własne hasło w .env
docker compose up --build
curl http://localhost:5080/health   # → Healthy
```

### Samo API, bez Dockera
```bash
dotnet run --project src/ExpenseSplitter.Api
```

## Struktura
```
src/
  ExpenseSplitter.Api/      # endpointy (Minimal APIs), Features/<Funkcja>/...
  ExpenseSplitter.Domain/   # czysta logika: pieniądze, podział, rozliczenia
docs/adr/                   # decyzje architektoniczne
```
