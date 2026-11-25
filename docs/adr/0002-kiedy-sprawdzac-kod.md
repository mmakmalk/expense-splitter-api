# ADR-0002: Kiedy Claude sprawdza kod: build po zmianie, testy na koniec

- **Data:** 2026-11-25
- **Status:** Zaakceptowana

## Kontekst
Chcemy, żeby Claude Code sam sprawdzał, czy kod działa, przez hooki (automatyczne odruchy). Są dwa rodzaje sprawdzania:
- **szybkie** (kilka sekund): czy kod się buduje (`dotnet build`)
- **wolne** (ok. 30 s): wszystkie testy, łącznie z testami integracyjnymi, które przez Testcontainers uruchamiają Postgresa w Dockerze

## Opcje
1. **Wszystko po każdej zmianie.** Błąd widać od razu, ale każda edycja czeka ok. 30 s.
2. **Po zmianie tylko build, wszystkie testy na koniec tury Claude'a.** Szybko. Wada: błąd w logice (np. w liczeniu pieniędzy) wychodzi dopiero na końcu.
3. **Po zmianie build i szybkie testy jednostkowe Domain, wolne testy na koniec.** Prawie tak szybko jak 2, a liczenie jest sprawdzane od razu. Wada: trochę dłuższy skrypt.

## Decyzja
Wybieramy **opcję 2**, żeby praca szła jak najszybciej.
Rekomendacją była opcja 3, ale na razie nie ma jeszcze testów Domain, więc obie działają tak samo. Wrócimy do tego w kroku z liczeniem pieniędzy (krok 6).

## Konsekwencje
- `PostToolUse` (Edit|Write|MultiEdit) → `.claude/hooks/build-after-edit.sh`: `dotnet build` po edycji pliku `.cs`/`.csproj`.
- `Stop` → `.claude/hooks/run-tests-on-stop.sh`: `dotnet test`, ale tylko gdy są niezacommitowane zmiany w kodzie. Dzięki temu zwykła odpowiedź na pytanie nie czeka 30 s.
- Jeśli testy nie przejdą, Claude nie może zakończyć tury i dostaje błędy do naprawy. Druga nieudana próba już go puszcza (`stop_hook_active`), żeby nie było nieskończonej pętli.
- Testy integracyjne wymagają działającego Docker Desktop.
- Zmiana na opcję 3 to dopisanie `dotnet test tests/ExpenseSplitter.Domain.Tests` w `build-after-edit.sh`.
