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

## Architektura
Zobacz `docs/adr/`. Najważniejsze:
- ADR-0001: vertical slices w `ExpenseSplitter.Api`, czysta logika w `ExpenseSplitter.Domain` (bez zależności od EF Core i ASP.NET).
