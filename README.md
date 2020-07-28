# Haxe Tween библиотека для JavaScript

Описание
------------------------------

Это маленькая, простая и надёжная библиотека для использования твинов в JS.
Дополняется по мере необходимости.

Зачем этому миру нужен ещё один твинер:
- Этот твинер не пытается <del>думать</del> оптимизировать за вас, он просто обновляет указанное ему свойство, точка. За счёт этого его реализация очень проста и надёжна. (В отличие от некоторых аналогов)
- Нормальное API.
- Твинит всё что угодно, от html dom элементов до шейдерных программ.
- Умеет твинить текстовые свойства, аля: `"10px"`. (См. Параметры твина)
- Поддерживает хаксовые геттер-сеттеры!
- В комплекте все стандартные функций изингов.
- Генерирует оптимальный JS.
- Неиспользуемый код выпиливается из проекта. (Haxe dce)
- Без зависимостей.

Пример использования
------------------------------
```
Tween.get(obj).to({x:500, y:0}, 1000, Ease.elasticInOut).to({visible:false});
```

Подключение в Haxe
------------------------------

1. Установите haxelib, чтобы можно было использовать библиотеки Haxe.
2. Выполните в терминале команду, чтобы установить библиотеку tween глобально себе на локальную машину:
```
haxelib git tween https://github.com/VolkovRA/HaxeTween master
```
Синтаксис команды:
```
haxelib git [project-name] [git-clone-path] [branch]
haxelib git minject https://github.com/massiveinteractive/minject.git         # Use HTTP git path.
haxelib git minject git@github.com:massiveinteractive/minject.git             # Use SSH git path.
haxelib git minject git@github.com:massiveinteractive/minject.git v2          # Checkout branch or tag `v2`.
```
3. Добавьте в свой проект библиотеку tween, чтобы использовать её в коде. Если вы используете HaxeDevelop, то просто добавьте в файл .hxproj запись:
```
<haxelib>
	<library name="tween" />
</haxelib>
```

Смотрите дополнительную информацию:
 * [Документация Haxelib](https://lib.haxe.org/documentation/using-haxelib/ "Using Haxelib")
 * [Документация HaxeDevelop](https://haxedevelop.org/configure-haxe.html "Configure Haxe")