# ADR-0005: Testy integracyjne: jeden kontener Postgresa i sprzątanie tabel przez Respawn

- **Data:** 2026-11-26
- **Status:** Zaakceptowana

## Kontekst
Testy integracyjne uruchamiają API w pamięci (`WebApplicationFactory`) z prawdziwym PostgreSQL w Dockerze (Testcontainers). Każdy test musi zaczynać od czystej bazy: jeśli test 1 doda grupę, test 2 nie może jej widzieć.

## Opcje
1. **Nowa baza dla każdego testu.** Zawsze w 100% czysto, ale wolno: 1–2 s na test.
2. **Sprzątanie tabel po każdym teście (Respawn).** Na Postgresie Respawn robi `TRUNCATE ... CASCADE` na wszystkich tabelach, w ułamku sekundy. Standard w .NET. Jedna biblioteka więcej.
3. **Transakcja cofana po teście.** Najszybsze, ale psuje się, gdy kod sam otwiera transakcje albo kilka połączeń, co daje trudne do zrozumienia błędy.

## Decyzja
**Opcja 2 (Respawn).** Dodatkowo, bez osobnej decyzji: **jeden kontener Postgresa na cały przebieg testów** (start ok. 5 s raz, a nie przy każdym teście).

## Konsekwencje
- `tests/ExpenseSplitter.Api.IntegrationTests/Infrastructure/ApiFactory.cs`: startuje kontener `postgres:18-alpine` (ta sama wersja co w `compose.yaml`) i podmienia `ConnectionStrings:Default`.
- Każda klasa testów dziedziczy po `IntegrationTest` i ma `[Collection(ApiCollection.Name)]`. Przed każdym testem baza jest czyszczona.
- Wszystkie klasy w jednej kolekcji są uruchamiane **po kolei, nie równolegle**, bo inaczej sprzątanie jednego testu kasowałoby dane drugiego. Jeśli testów będzie dużo i zrobi się wolno, wrócimy do tego (np. osobna baza na kolekcję).
- Tabela `__EFMigrationsHistory` nie jest czyszczona, bo EF Core zapomniałby, że schemat już istnieje.
- `TRUNCATE` nie cofa liczników ID, więc po sprzątaniu restartujemy też wszystkie sekwencje w `public`: pierwszy wiersz w każdym teście znowu dostaje id 1.
- `TRUNCATE` potrzebuje wyłącznej blokady tabeli. Jeśli API zostawi otwartą transakcję, sprzątanie będzie czekać. Test, który tworzy własne tabele, musi je usunąć na końcu, bo baza jest wspólna.
- Respawner jest budowany od nowa przy każdym sprzątaniu (kilka ms), więc tabele dodane później nie zostaną pominięte. Na bazie bez tabel sprzątanie nic nie robi.
- Testy wymagają działającego Docker Desktop.
