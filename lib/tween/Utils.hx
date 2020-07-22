package tween;

import js.Syntax;

/**
 * Вспомогательные утилиты.
 */
@:dce
class Utils 
{
    /**
     * Получить метку текущей даты. (mc)
     * 
     * Метод возвращает количество миллисекунд, прошедших
     * с 1 января 1970 года 00:00:00 по UTC по текущий момент
     * времени в качестве числа.
     * 
     * @return Временная метка.
     * @see `Date.now()`: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/now
     */
    public static inline function stamp():Float {
        return Syntax.code('Date.now()');
    }

    /**
     * Нативный JS вызов `delete` для удаления свойств объектов.
     * @param property Удаляемое свойство.
     * @return Возвращает `false`, только если свойство существует в самом объекте, а не в его прототипах,
     *         и не может быть удалено. Во всех остальных случаях возвращает `true`.
     * @see Документация: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/delete
     */
    public static inline function delete(property:Dynamic):Bool {
        return Syntax.code("delete {0}", property);
    }

    /**
     * Строговое равенство. (`===`).
     * 
     * Возможность использовать в Haxe чуть более быстрое сравнение JavaScript без авто-приведения типов.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param v1 Значение 1.
     * @param v2 Значение 2.
     * @return Результат сравнения.
     */
    static public inline function eq(v1:Dynamic, v2:Dynamic):Bool {
        return Syntax.code('({0} === {1})', v1, v2);
    }

    /**
     * Строговое неравенство. (`!==`).
     * 
     * Возможность использовать в Haxe чуть более быстрое сравнение JavaScript без авто-приведения типов.
     * Генерирует оптимальный JS код и встраивается в точку вызова.
     * 
     * @param v1 Значение 1.
     * @param v2 Значение 2.
     * @return Результат сравнения.
     */
    static public inline function noeq(v1:Dynamic, v2:Dynamic):Bool {
        return Syntax.code('({0} !== {1})', v1, v2);
    }

    /**
     * Строгая проверка на `NaN`. (`isNaN(v)`).
     * @param v Сравниваемое значение.
     * @return Результат сравнения.
     */
    static public inline function isNaN(v:Dynamic):Bool {
        return Syntax.code('isNaN({0})', v);
    }

    /**
     * Строгая проверка на `undefined`. (`v === undefined`).
     * @param v Сравниваемое значение.
     * @return Результат сравнения.
     */
    static public inline function isUnd(v:Dynamic):Bool {
        return Syntax.code('({0} === undefined)', v);
    }

    /**
     * Проверка значения на конечное число. (Не учитывает `null`)
     * 
     * Функция определяет, является ли переданное значение конечным числом.
     * Если необходимо, параметр сначала преобразуется в число.
     * 
     * ```
     * isFinite(Infinity);  // false
     * isFinite(NaN);       // false
     * isFinite(-Infinity); // false
     * 
     * isFinite(0);         // true
     * isFinite(2e64);      // true
     * isFinite(910);       // true
     * 
     * isFinite(null);      // true
     * isFinite('0');       // true
     * ```
     * @param v Проверяемое значение.
     * @return Возвращает `true`, если это конечное число, `null` или число в строке.
     * @see isFinite: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/isFinite
     */
    static public inline function isFinite(v:Dynamic):Bool {
        return Syntax.code('isFinite({0})', v);
    }

    /**
     * Проверка значения на числовой тип.
     * @param v Проверяемое значение.
     * @return Возвращает `true`, если это числовой тип. (В том числе: `NaN` или `Infinity`)
     */
    static public inline function isNumber(v:Dynamic):Bool {
        return Syntax.code('(typeof {0} === "number")', v);
    }

    /**
     * Приведение к `String`.
     * 
     * Нативное JavaScript приведение любого значения к строке.
     * 
     * @param v Значение.
     * @return Строка.
     */
    static public inline function str(v:Dynamic):String {
        return Syntax.code("({0} + '')", v);
    }
}