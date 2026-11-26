# Expense Splitter API

API do dzielenia wspólnych wydatków w grupie: kto zapłacił, ile i kto komu ile oddaje.
Stack: ASP.NET Core, PostgreSQL, EF Core (migracje), JWT, Docker Compose, testy integracyjne z Testcontainers.

## Zasady współpracy
1. Nie piszemy kodu, dopóki decyzja, której dotyczy, nie jest zatwierdzona.
2. Przy każdej ważnej decyzji: 2–3 opcje (zalety, wady, kiedy lepsza) i rekomendacja. Wybiera właściciel projektu.
3. Każda zatwierdzona decyzja trafia jako ADR do `docs/adr/` (szablon: `docs/adr/0000-szablon.md`).
4. Jeden krok = jeden branch = jeden PR. Po każdym kroku: co powstało, jak działa w środku, co może się zepsuć.
5. Słabszy wybór mówimy wprost.
6. Tłumaczymy prostymi słowami i z rysunkiem (tablica).

## Git
- Nigdy nie pushujemy bezpośrednio na `main`. Zawsze branch, a potem PR.
- Nazwy branchy: `feat/...`, `fix/...`, `chore/...`, `test/...`, `docs/...`, `ci/...`.
- Każdy PR przed mergem przechodzi `/code-review` i `/security-review`.

## Automatyzacja Claude Code (`.claude/`)
- `hooks/block-push-main.sh` (PreToolUse, Bash): blokuje push na `main`/`master`, force push (`--force`, `-f`, `+refspec`), `--mirror` i `--all`.
- `hooks/build-after-edit.sh` (PostToolUse, Edit/Write): `dotnet build` po edycji pliku `.cs`/`.csproj`/`.props`/`.targets`/`.sln(x)`.
- `hooks/run-tests-on-stop.sh` (Stop): `dotnet test` na koniec tury, gdy kod się zmienił. Maksymalnie 3 próby naprawy. Wymaga działającego Dockera.
- `hooks/lib.sh`: wspólne funkcje (czytanie pól z JSON-a hooka bez `jq`).
- `settings.json`: lista tego, co wolno bez pytania (build, test, git status...), i tego, czego nie wolno nigdy (.env, force push, reset --hard, merge PR).
- Własne ustawienia lokalne trzymaj w `.claude/settings.local.json` (nie trafia do gita).

## Architektura
Zobacz `docs/adr/`. Najważniejsze:
- ADR-0001: vertical slices w `ExpenseSplitter.Api`, czysta logika w `ExpenseSplitter.Domain` (bez zależności od EF Core i ASP.NET).
- ADR-0003: .NET 10. Wspólne ustawienia w `Directory.Build.props` (ostrzeżenia = błędy).
- ADR-0004: Minimal APIs. Jeden endpoint = jeden plik w `Features/<Funkcja>/`. Bez MediatR.
- ADR-0005: testy integracyjne z prawdziwym Postgresem (Testcontainers), jeden kontener na przebieg, czyszczenie bazy przez Respawn przed każdym testem.

## Testy
- Integracyjne: `tests/ExpenseSplitter.Api.IntegrationTests`. Nowa klasa testów:
  `[Collection(ApiCollection.Name)] public class XTests(ApiFactory api) : IntegrationTest(api)`.
  Masz wtedy `Client` (HttpClient do API) i czystą bazę na starcie każdego testu.
- Nazwy testów opisują zachowanie: `Health_returns_200_Healthy`.
- Wymagają działającego Docker Desktop.

## Komendy
- Build: `dotnet build ExpenseSplitter.slnx`
- Testy: `dotnet test ExpenseSplitter.slnx`
- API + baza: `docker compose up --build` (wymaga `.env`, wzór w `.env.example`)
- Health check: `GET /health`
