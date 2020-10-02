Podstawowe struktury danych
===========================

  * `FrameData` (w `SpriteLib.hx`).  Zawiera `Tile`, współrzędne `x`, `y` i
    wymiary sprajta (zapewne po to żeby dało się opisać lokację jednego sprajta
    na arkuszu).  Do tego są kopie tych współrzędnych z przedrostkiem `real`,
    ale nie wiem po co.  Może skalowanie jakieś?  `Tile` jest używany tylko
    jeśli nie są wykorzystywane makra - nie wiem czemu.

  * `LibGroup` (w `SpriteLib.hx`).  Zawiera listę `FrameData` oraz listę intów
    opisującą klatki animacji.  Czyli z grubsza to jest animacja (klatki +
    informacje o ich wzajemnym ułożeniu i ew. powtórzeniu)


SpriteInterface
===============

Abstrakcyjny interfejs sprajta zawierający:

  * dane klatek animacji (w postaci `LibGroup`, `FrameData` i numeru klatki)
  * wskazanie na `SpriteLib` i `AnimManager` - nie wiem po co
  * funkcje do ustawiania parametrów sprajta (wymiary, aktywna klatka, pivot,
    skalowanie)


HSprite
=======

[Source](https://github.com/deepnight/deepnightLibs/blob/master/src/dn/heaps/slib/HSprite.hx#L12)

Najważniejsze jest to że ten obiekt dziedziczy po `h2d.Drawable` i tym samym
może być wpięty do hierarchii renderowania heapsa.

Użycie
------

Ten obiekt jest tworzony dla każdego Entity z `Assets.tiles`, które jest typu
`SpriteLib`, potem jest dodawany do warsty scroller (jak rozumiem to jakaś
"naczelna" warstwa dla gry), ustawia mu się środek i ewentualny kolor jeżeli go
chcemy kolorować. Samo ustawianie animacji (rejestrowanie możliwych stanów)
odbywa się w `new` klasy dziedziczącej z Entity.

Sprite jest aktualizowany w `postUpdate` (jego położenie, skala i czy jest
widoczny) i usuwany on dispose.


Zależności
----------

HSprite odwołuje się do kilku obiektów:

  - `SpriteLib`

  - `LibGroup` - prosta struktura co ma id, rozmiary sprite'a, listę `FrameData`
    (po co to powtórzenie?) i listę intów wskazujące na animację

  - `AnimManager` (co ciekawe, w metodzie `set` HSprite podaje sam siebie do
    jego konstruktora)

  - `FrameData` - prosta struktura, która definiuje masę `Int`ów dla określania
    `page`, x, y, wysokości/szerokości (obie mają wartości zwykłe i "real") i
    `Tile`, jeżeli nie ma zdefiniowanego macro (cokolwiek to znaczy)

  - `SpritePivot` - wektor na sterydach

  - `rawTile : Tile`


Inicjalizacja
-------------

Najpierw inicjalizowane są rzeczy związanie z `Drawable` (wywołujemy `super` i
podajemy rodzica jak jest) i nudy w sumie - tworzony jest pivot i jak podaliśmy
`l : SpriteLib`, wywoływania jest funkcja `set`, która robi więcej niż nazwa
wskazuje. W przeciwnym razie, inicjalizujemy pustą teksturę.


Interesujące funkcje
--------------------

  - `set` - najpierw sprawdzane jest czy mamy zdefiniowaną tablicę `Tiles` z
    danego sprite'a. Resetowane są informacje o grupie i ramkach i potem
    ustawiany jest ten lib dla HSprite. Jakaś magia z dodawaniem i usuwaniem
    dzieci jest, nie wiem. Potem ustawiamy nazwę grupy, jeżeli została
    przekazana jako parametr. Jeżeli obiekt jest "dobry" (`isReady` ==
    animManager i groupName są zdefiniowane + obiekt nie jest oznaczony jako
    usunięty), zainicjalizuje `frameData`, `group` i `rawTile` używając `lib :
    SpriteLib`, który żyje sobie w `HSprite`. Nie rozumiem czemu `l : SpriteLib`
    jest parametrem opcjonalnym, skoro wszelakie inity wkoło tego się kręcą.

  - `setFrame` - jeżeli obiekt jest "dobry", wybieramy ze SpriteLib klatkę `f`
    (przekazywaną jako parametr) bazując na groupName i przypisujemy do
    `frameData`. Jeżeli ostatnia klatka `lastFrame : Int` (pole zdefiniowane
    przez [Object](https://heaps.io/api/h2d/Object.html)) nie jest tą samą co
    wskazywaną przez `frameData.page`, podmieniamy teksturę i ustawiamy zmienną
    `lastPage` (zdefiniowaną dla `HSprite`, nie jestem pewna jak to się ma do
    `lastFrame`).

Inne
----

Funkcji trochę jest i były wykorzystywane przez nas na jamie - możemy zmieniać
kolorki, skalę, pivoty i takie tam. Są zdefiniowane jakieś eventy `onAdd`,
`onRemove`, może jest to jakoś związane z warstwami? Albo procesami?

Zauważyłam, że są wersje `HSpriteBE` i `HSpriteBatch` (ten ostatni używa
pierwszego). Wygląda baardzo podobnie do zwykłego, oferuje fajną funkcję
[`updateTile`](https://github.com/deepnight/deepnightLibs/blob/master/src/dn/heaps/slib/HSpriteBE.hx#L198)
Nie wiem na czym polega to przetwarzanie w batchu.

SpriteLib
=========

[Source](https://github.com/deepnight/deepnightLibs/blob/master/src/dn/heaps/slib/SpriteLib.hx#L53)

Nadal nie czaję co to są `pages : Array<Tiles>` - można mieć wiele spritesheetów
w ramach jednego pliku? Widziałam, że ten lib jest tworzony w `parseXml` w
TexturePacker.hx

AnimManager
===========

[Source](https://github.com/deepnight/deepnightLibs/blob/master/src/dn/heaps/slib/AnimManager.hx#L85)

Całkiem spora klasa, odwołuje się do `AnimInstance`, `StateAnim` i `Transition`,
wszystkie są zdefiniowane w tym pliku. To je serce animacji i przełączania!

Klasy wewnętrzne:

  * `AnimInstance` opisuje logiczne aspekty animacji (zapętlenie, prędkość
    odtwarzania, odtwarzanie od tyłu, ilość odtworzeń, czy skończona, czy
    zapauzowana).  Zawiera obiekt będący `SpriteInterface` oraz listę klatek,
    potencjalnie zduplikowaną z obiektu sprajta.  Funkcja `applyFrame` ustawia
    aktualną klatkę w obiekcie `SpriteInterface` oraz opcjonalnie odtwarza
    callback przy wejściu do nowej klatki animacji.  Posiada callbacki `onEnd` i
    `onEachLoop`.

  * `StateAnim`.  Najważniejsze to funkcja `cond : Void -> Bool` mówiąca czy
    daną animację należy ustawić jako aktywną.  Używaliśmy tego bardzo
    intensywnie na gamejamie.  Nie analizowałem co się dzieje z innymi polami
    tej klasy (`group`, `priority`).

  * `Transition` w jakiś sposób opisuje przejścia animacji, ale jeszcze nie
    kumam jak bo pola `from`, `to`, i `anim` są stringami.  Do tego funkcja
    `cond` taka jak w `StateAnim` oraz pola `speed` i `reverse`.

`AnimManager` zawiera stos animacji do odtworzenia (obiekty `AnimInstance`) oraz
listę stanów `StateAnim` i przejść `Transition`.  Do tego flagi opisujące stan
animacji.  Metody pozwalają na:

  * odczytywanie czasów trwania animacji w sekundach i klatkach.  Uwzględniają
    prędkości animacji (np. przyspieszenie) i FPSy.
  * wszelkiego rodzaju odpytywanie stanu animacji
  * układanie animacji w kolejkę, zarządzanie jej strukturą

Kluczowa funckjonalność klasy z grubsza sprawdza się do możliwości tworzenia
struktury animacji (stos animacji + przypisane im ilości powtórzeń, prędkości
odtwarzania itp.), a następnie sprytne odtwarzanie tego w metodzie update.
