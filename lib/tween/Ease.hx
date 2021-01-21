package tween;

/**
 * Функций изингов. 🎢  
 * Статический класс `Ease` предоставляет доступ к готовым
 * функциям изингов и к их расширенным конструкторам, для
 * построения новых.
 * 
 * Функций изингов позаимствованы из библиотеки CreateJS,
 * которые в свою очередь взяты у Robert Penner.
 * 
 * @see TweenJS: https://www.createjs.com/docs/tweenjs/files/tweenjs_Ease.js.html#l39
 */
@:dce
class Ease
{
    /**
     * Линейное движение. *(По умолчанию)*
     */
    static public var linear:EaseFunction = function(t) { return t; }

    static public var quadIn:EaseFunction = Ease.getPowIn(2);
    static public var quadOut:EaseFunction = Ease.getPowOut(2);
    static public var quadInOut:EaseFunction = Ease.getPowInOut(2);

    static public var cubicIn:EaseFunction = Ease.getPowIn(3);
    static public var cubicOut:EaseFunction = Ease.getPowOut(3);
    static public var cubicInOut:EaseFunction = Ease.getPowInOut(3);

    static public var quartIn:EaseFunction = Ease.getPowIn(4);
    static public var quartOut:EaseFunction = Ease.getPowOut(4);
    static public var quartInOut:EaseFunction = Ease.getPowInOut(4);

    static public var quintIn:EaseFunction = Ease.getPowIn(5);
    static public var quintOut:EaseFunction = Ease.getPowOut(5);
    static public var quintInOut:EaseFunction = Ease.getPowInOut(5);

    static public var sineIn:EaseFunction = function(t) { return 1-Math.cos(t*Math.PI/2); }
    static public var sineOut:EaseFunction = function(t) { return Math.sin(t*Math.PI/2); }
    static public var sineInOut:EaseFunction = function(t) { return -0.5*(Math.cos(Math.PI*t) - 1); }

    static public var backIn:EaseFunction = Ease.getBackIn(1.7);
    static public var backOut:EaseFunction = Ease.getBackOut(1.7);
    static public var backInOut:EaseFunction = Ease.getBackInOut(1.7);

    static public var circIn:EaseFunction = function(t) { return -(Math.sqrt(1-t*t)- 1); }
    static public var circOut:EaseFunction = function(t) { return Math.sqrt(1-(--t)*t); }
    static public var circInOut:EaseFunction = function(t) {
        if ((t*=2) < 1) return -0.5*(Math.sqrt(1-t*t)-1);
        return 0.5*(Math.sqrt(1-(t-=2)*t)+1);
    };

    static public var bounceIn:EaseFunction = function(t) {
        return 1-Ease.bounceOut(1-t);
    };
    static public var bounceOut:EaseFunction = function(t) {
        if (t < 1/2.75) return (7.5625*t*t);
        if (t < 2/2.75) return (7.5625*(t-=1.5/2.75)*t+0.75);
        if (t < 2.5/2.75) return (7.5625*(t-=2.25/2.75)*t+0.9375);
        return (7.5625*(t-=2.625/2.75)*t +0.984375);
    };
    static public var bounceInOut:EaseFunction = function(t) {
        if (t<0.5) return Ease.bounceIn (t*2) * .5;
        return Ease.bounceOut(t*2-1)*0.5+0.5;
    };

    static public var elasticIn:EaseFunction = Ease.getElasticIn(1,0.3);
    static public var elasticOut:EaseFunction = Ease.getElasticOut(1,0.3);
    static public var elasticInOut:EaseFunction = Ease.getElasticInOut(1,0.3*1.5);

    /**
     * Конфигурируемая, экспоненциальная функция.
     * @param pow Используемая экспонента. (Значение `3` вернёт кубический изинг)
     */
    static public function getPowIn(pow:Float):EaseFunction { 
        return function(t) { 
            return Math.pow(t,pow);
        }
    }

    /**
     * Конфигурируемая, экспоненциальная функция.
     * @param pow Используемая экспонента. (Значение `3` вернёт кубический изинг)
     */
    static public function getPowOut(pow:Float):EaseFunction {
        return function(t) {
            return 1-Math.pow(1-t,pow);
        }
    }

    /**
     * Конфигурируемая, экспоненциальная функция.
     * @param pow Используемая экспонента. (Значение `3` вернёт кубический изинг)
     */
    static public function getPowInOut(pow:Float):EaseFunction {
        return function(t) {
            if ((t*=2)<1) return 0.5*Math.pow(t,pow);
            return 1-0.5*Math.abs(Math.pow(2-t,pow));
        }
    }

    /**
     * Конфигурируемая `backIn` функция.
     * @param amount Сила применения.
     */
    static public function getBackIn(amount:Float):EaseFunction {
        return function(t) {
            return t*t*((amount+1)*t-amount);
        }
    }

    /**
     * Конфигурируемая `backOut` функция.
     * @param amount Сила применения.
     */
    static public function getBackOut(amount:Float):EaseFunction {
        return function(t) {
            return (--t*t*((amount+1)*t + amount) + 1);
        }
    }

    /**
     * Конфигурируемая `backInOut` функция.
     * @param amount Сила применения.
     */
    static public function getBackInOut(amount:Float):EaseFunction {
        amount*=1.525;
        return function(t) {
            if ((t*=2)<1) return 0.5*(t*t*((amount+1)*t-amount));
            return 0.5*((t-=2)*t*((amount+1)*t+amount)+2);
        };
    }

    /**
     * Конфигурируемая `elasticIn` функция.
     * @param amplitude Амплитуда.
     * @param period Периуд.
     */
    static public function getElasticIn(amplitude:Float, period:Float):EaseFunction {
        var pi2 = Math.PI*2;
        return function(t) {
            if (t==0 || t==1) return t;
            var s = period/pi2*Math.asin(1/amplitude);
            return -(amplitude*Math.pow(2,10*(t-=1))*Math.sin((t-s)*pi2/period));
        };
    }

    /**
     * Конфигурируемая `elasticOut` функция.
     * @param amplitude Амплитуда.
     * @param period Периуд.
     */
    static public function getElasticOut(amplitude:Float, period:Float):EaseFunction {
        var pi2 = Math.PI*2;
        return function(t) {
            if (t==0 || t==1) return t;
            var s = period/pi2 * Math.asin(1/amplitude);
            return (amplitude*Math.pow(2,-10*t)*Math.sin((t-s)*pi2/period )+1);
        };
    }

    /**
     * Конфигурируемая `elasticInOut` функция.
     * @param amplitude Амплитуда.
     * @param period Периуд.
     */
    static public function getElasticInOut(amplitude:Float, period:Float):EaseFunction {
        var pi2 = Math.PI*2;
        return function(t) {
            var s = period/pi2 * Math.asin(1/amplitude);
            if ((t*=2)<1) return -0.5*(amplitude*Math.pow(2,10*(t-=1))*Math.sin( (t-s)*pi2/period ));
            return amplitude*Math.pow(2,-10*(t-=1))*Math.sin((t-s)*pi2/period)*0.5+1;
        };
    }
}

/**
 * Функция изинга. 🏄  
 * В самом простом понимании любая функция изинга
 * это обычная функция: `f(x)`, принимающая и
 * возвращающая значения в диапазоне от: `0` до: `1`
 */
typedef EaseFunction = Float->Float;