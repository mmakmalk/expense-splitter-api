# ADR-0004: Minimal APIs zamiast kontrolerów

- **Data:** 2026-11-26
- **Status:** Zaakceptowana

## Kontekst
Musimy ustalić, jak w kodzie definiujemy endpointy (adresy API, np. `POST /groups`).

## Opcje
1. **Kontrolery:** jedna klasa na zasób (`GroupsController`) z wieloma metodami. Klasyczne i dobrze opisane, ale to więcej kodu, a wszystkie akcje grupy lądują w jednej dużej klasie. Słabo pasuje do vertical slices (ADR-0001).
2. **Minimal APIs:** każdy endpoint to `MapPost`/`MapGet` z funkcją, a każdy może leżeć w osobnym pliku w `Features/<Funkcja>/`. Mało kodu, pasuje do slices i do skilla `/new-endpoint`, w tę stronę rozwija się ASP.NET Core. Wada: porządek (grupowanie, rejestracja) ustalamy sami.

## Decyzja
**Minimal APIs.**

## Konsekwencje
- Jeden endpoint = jeden plik w `src/ExpenseSplitter.Api/Features/<Funkcja>/`.
- Wspólny sposób rejestrowania endpointów ustalimy przy pierwszej prawdziwej funkcji (krok 5) i zapiszemy w skillu `/new-endpoint`.
- Bez MediatR (płatna licencja od 2025, ADR-0001). Endpoint wywołuje logikę bezpośrednio.
