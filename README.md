## Содержимое репозитория
- dzdz.pml - исходный код околоSDN
- no_dlock.sh и no_neg_ules.sh - скрпипты запуска проверок

## Запуск проверок

Спин не позволяет за один ран проверить несколько утверждений.
Поэтому репозитории есть два скрипта:
- no_dlock.sh     (чек на дедлоки)
- no_neg_ules.sh  (чек на неотрицательное кол-во правил)

## Результаты

Требовалось доказать два свойства системы:
- в системе отсутствуют дедлоки - T
- кол-во правил в комке и кол-во правил в комке 
  (с т.з. контроллера и приложения) неотрицательны - F

Лог невыполненного утверждения:
```
 (Spin Version 6.5.2 -- 6 December 2019)
 Warning: Search not completed
       + Breadth-First Search

 Full statespace search for:
       never claim             + (no_neg_rules)
       assertion violations    + (if within scope of claim)
       cycle checks            - (disabled by -DSAFETY)
       invalid end states      - (disabled by never claim)

 State-vector 116 byte, depth reached 106, errors: 1
   82880 states, stored
          57856 nominal states (- rv and atomic)
           3237 rvs succeeded
  172970 states, matched
  255850 transitions (= stored+matched)
       4 atomic steps
 hash conflicts:       231 (resolved)

 Stats on memory usage (in Megabytes):
  10.750       equivalent memory usage for states (stored*(State-vector + overhead))
  10.231       actual memory usage for states (compression: 95.18%)
               state-vector as stored = 109 byte + 20 byte overhead
 128.000       memory used for hash table (-w24)
 138.156       total actual memory usage



pan: elapsed time 0.08 seconds
pan: rate   1036000 states/second
```
