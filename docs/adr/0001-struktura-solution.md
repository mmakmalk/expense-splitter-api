# ADR-0001: Struktura solution: vertical slices i osobny projekt Domain

- **Data:** 2026-11-25
- **Status:** Zaakceptowana

## Kontekst
Musimy ustalić, jak podzielić kod na projekty i foldery. Aplikacja to w większości proste operacje (grupy, członkowie, logowanie). Ma też jedną trudną część: liczenie pieniędzy (dzielenie kwot, zaokrąglenia, kto komu ile oddaje). Na projekt mamy około 2 tygodni.

## Opcje
1. **Clean Architecture (4 projekty: Api, Application, Infrastructure, Domain).**
   Porządku pilnuje kompilator i jest to znany wzorzec. Wada: dużo plików i przeskakiwania między projektami przy każdej drobnej zmianie, za ciężkie na 2 tygodnie.
2. **Vertical slices w jednym projekcie.** Każda funkcja ma swój folder (`Features/Groups/...`).
   Szybko i mało pisania, dobrze pasuje do skilla `/new-endpoint`. Wada: nic nie wymusza, żeby logika liczenia pieniędzy była w jednym miejscu, więc łatwo o duplikaty i błędy.
3. **Hybryda: vertical slices w `Api` plus osobny, czysty projekt `Domain`.**
   `Domain` nie zależy od niczego (ani od EF Core, ani od ASP.NET). Trzyma encje, `Money`, algorytmy podziału i rozliczeń. Wada: trochę więcej ustawiania na starcie.

## Decyzja
Wybieramy **opcję 3 (hybrydę)**. Najwięcej ryzyka siedzi w liczeniu pieniędzy, więc ta część dostaje własny projekt, który da się testować szybkimi testami jednostkowymi bez bazy i bez Dockera. Reszta zostaje lekka, w układzie „jedna funkcja = jeden folder”.

Planowany układ:
```
src/
  ExpenseSplitter.Api/        # endpointy, EF Core, auth, Features/<Funkcja>/...
  ExpenseSplitter.Domain/     # czysta logika: encje, Money, podział, rozliczenia
tests/
  ExpenseSplitter.Domain.Tests/          # testy jednostkowe (szybkie)
  ExpenseSplitter.Api.IntegrationTests/  # testy z prawdziwym Postgresem (Testcontainers)
```

## Konsekwencje
- `Domain` nie może mieć referencji do EF Core ani ASP.NET Core. Pilnuje tego kompilator.
- Konfiguracja bazy (mapowanie encji) jest w `Api`, przez Fluent API, a nie przez atrybuty w encjach.
- Logika liczenia pieniędzy nie może trafiać do handlerów w `Features/`. Handler ma tylko wywoływać `Domain`.
- Nie używamy MediatR (płatna licencja od 2025). Handlery to zwykłe klasy. Szczegóły ustalimy przy decyzji „Minimal APIs czy kontrolery”.
