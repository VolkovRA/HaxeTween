package tween;

import haxe.Constraints.Function;
import js.Browser;
import js.Syntax;
import js.lib.Error;
import tween.Ease;

/**
 * Твинер.
 * 
 * Для общего понимания твинер можно представить себе как небольшой плеер микропрограммы,
 * которую вы емую задаёте. Во время воспроизведения твинер идёт шаг за шагом и поочереди
 * исполняет заданные ему действия.
 * 
 * Использование:
 * 1. Для получения экземпляра класса вы можете вызвать конструктор или использовать
 *    статический метод: `Tween.get()`.
 * 2. После получения экземпляра добавьте в него действия: `to()`, `wait()`, `call()`
 *    и т.п. Действия будут выполняться по очереди. Добавленные действия нельзя удалить.
 * 3. Новый твинер находится в режиме воспроизведения, вызов `play()` не требуется.
 * 4. Вы можете управлять ходом выполнения анимации через экземпляр класса `Tween`
 *    или забить на него. (Он будет удалён сборщиком мусора после завершения воспроизведения)
 * 
 * Сборка мусора:
 * - Все активные твинеры имеют ссылку и не могут быть удалены.
 * - Не активные твинеры и твинеры на паузе удаляются из общего реестра и могут быть собраны
 *   сборщиком, если на них нет других ссылок.
 */
class Tween
{
    /**
     * Максимальное количество обрабатываемых действий за одно обновление.
     */
    static private inline var MAX_CALLS = 10;

    private var a:Array<Action> = [];   // Порядок задач для воспроизведения.
    private var ai:Int = -1;            // Индекс текущего действия.
    private var ap:Float = 0;           // Прогресс выполнения текущего действия. (mc или scale) Миллисекунды, если задача имеет duration>0, 0 или 1 в других случаях.
    private var si:Int = -1;            // Индекс положения в общем кеше для быстрого поиска.
    private var stp:Int = 0;            // Счётчик вызовов step() для предотвращения раннего обновления.
    private var upd:Int = 0;            // Счётчик вызовов update() для исключения вызова в вызове.
    private var opt:TweenOptions;

    /**
     * Создать новый твиннер.
     * @param target Управляемый объект.
     * @param options Дополнительные параметры.
     * @throws Error Цель твина не должна быть `null`.
     */
    public function new(target:Dynamic, options:TweenOptions = null) {
        if (target == null)
            throw new Error("Tween target cannot be null");

        this.target = target;
        this.opt = options;

        if (options == null) {
            addTween(this);
        }
        else {
            if (options.bounce)
                bounce = true;
            if (options.reversed)
                reversed = true;
            if (options.loop != null)
                loop = options.loop;
            if (options.speed != null)
                speed = options.speed;
            if (options.clear)
                Tween.stop(target);
            if (!options.stopped)
                addTween(this);
        }
    }



    //////////////////
    //   СВОЙСТВА   //
    //////////////////

    /**
     * Цель анимации.
     * 
     * Это свойство ссылается на объект, свойства которого будут анимированы.
     * 
     * Не может быть `null`.
     */
    public var target(default, null):Dynamic;

    /**
     * Счётчик количества повторных циклов воспроизведения.
     * - Один проход в любую сторону считается за один цикл.
     * - Автоматически уменьшается на `1` при запуске очередного цикла.
     *   (Пока не дойдёт до `0`)
     * - Значение `-1` (или меньше) приводит к бесконечному воспроизведению.
     * 
     * Если вы используете `bounce=true`, то вам нужно установить это
     * значение в `1`, чтобы цикл с обратной анимацией тоже проигрался.
     * 
     * По умолчанию: `0` (Одно проигрывание)
     */
    public var loop:Int = 0;

    /**
     * Обратное воспроизведение в конце каждого цикла.
     * 
     * Меняет направление движения на противоположное в конце каждого
     * цикла анимации. Проход анимации в одном направлении считается за
     * один цикл, поэтому, если вы используете это свойство, вы должны
     * установить значение `loop=1`, чтобы увидеть обратную анимацию.
     * 
     * По умолчанию: `false`
     */
    public var bounce:Bool = false;

    /**
     * Воспроизведение анимации в обратном направлении.
     * 
     * По умолчанию: `false`
     */
    public var reversed:Bool = false;

    /**
     * Твин остановлен.
     * - Если `true`, этот твин не воспроизводится и может быть удалён
     *   сборщиком мусора, если на него нет других ссылок. Остановленные
     *   твины не воспроизводятся, если в них добавляются новые действия.
     *   Для запуска твина вы должны вызвать метод: `play()` или `goto()`.
     *   Все твины автоматически останавливаются, когда завершается их
     *   анимация или если были вызваны методы: `pause()`, `stop()`, `stopAll()`.
     * - Если `false`, этот твин считается активным и на него есть ссылка
     *   в общем реестре всех твинов. Он автоматически остановится, когда
     *   вся анимация будет проиграна. (Если не задан бесконечный цикл)
     * 
     * По умолчанию: `false` (Проигрывается)
     */
    public var stopped(get, never):Bool;
    inline function get_stopped():Bool {
        return Utils.eq(si, -1);
    }

    /**
     * Текущая позиция воспроизведения.
     * 
     * Содержит нормализованную позицию анимации, где:
     * - `0` - Начало анимации.
     * - `1` - Конец анимации, по времени соответствующий: `duration`.
     * 
     * Это значение не может быть меньше `0` или больше `1`.
     * Для получения позиции в миллисекундах используйте: `position*duration`.
     * 
     * Обратите внимание, что при установке этого значения вручную будут
     * пропущены действия между исходной и новой позициями. Это касается,
     * в первую очередь, вызываемых колбеков: `call()` и коротких действий
     * с `duration=0`. Если вам нужно выполнить все действия между позициями,
     * используйте метод: `update()`. Добавление в твин новых действий смещает
     * position влево.
     * 
     * *Детали реализации:*
     * *Свойство position является отражением общего прогресса выполнения твина*
     * *для более упрощённого внешнего API. Этот прогресс, фактически, содержится*
     * *в приватных переменных: ai и ap. (Индекс действия, прогресс действия)*
     * 
     * По умолчанию: `0`
     */
    public var position(get, set):Float;
    function get_position():Float {
        var len = a.length;
        if (Utils.eq(len, 0))
            return ap; // <-- В пустом списке может быть только 0 или 1.
        if (Utils.eq(duration, 0))
            return (ai+(ap==0?0:1))/len; // <-- С нулевой длительностью ap может быть только 0 или 1.

        return (a[ai].prev+ap)/duration; // <-- Тут задача с временем, ap измеряется в миллисекундах прогресса.
    }
    function set_position(value:Float):Float {
        var v:Float = 0;
        if (value > 0)
            v = value;
        if (v > 1)
            v = 1;

        var len = a.length;
        if (len == 0) {
            ap = value<0.5?0:1;
        }
        else if (Utils.eq(duration, 0)) {
            ai = untyped Math.min(len-1, Math.floor(v*len));
            ap = (v*len)-ai<0.5?0:1;
        }
        else {
            if (v == 0) {
                ai = 0;
                ap = 0;
            }
            else if (v == 1) {
                ai = len-1;
                ap = 1;
            }
            else {
                var t = v * duration;
                while (len-- != 0) {
                    if (t < a[len].prev)
                        continue;
                    ai = len;
                    ap = (t-a[len].prev)/a[len].duration;
                    return value;
                }
            }
        } 

        return value;
    }

    /**
     * Общая продолжительность всех анимаций. (mc)
     * 
     * Это значение содержит общее время всех анимаций твина без учёта
     * циклов. Обновляется автоматически при добавлении новых действий.
     * 
     * По умолчанию: `0`
     */
    public var duration(default, null):Float = 0;

    /**
     * Скорость воспроизведения. (scale)
     * - Это значение не может быть меньше `0`.
     * 
     * По умолчанию: `1` (Обычная скорость)
     */
    public var speed(default, set):Float = 1;
    function set_speed(value:Float):Float {
        if (value > 0)
            speed = value;
        else
            speed = 0;

        return value;
    }



    ////////////////
    //   МЕТОДЫ   //
    ////////////////

    /**
     * Остановить анимацию.
     * 
     * Вызов игнорируется, если твинер уже остановлен. Остановленные твинеры не
     * имеют ссылки и могут быть удалены сборщиком мусора. (Если других ссылок нет)
     */
    public function pause():Void {
        if (stopped)
            return;

        removeTween(this);
    }

    /**
     * Продолжить анимацию.
     */
    public function play():Void {
        if (!stopped)
            return;

        addTween(this);
    }

    /**
     * Продвинуть анимацию твина.
     * - Поддерживаются отрицательные значения для инверсии анимации.
     * @param time Прошедшее время. (mc)
     */
    public function update(time:Float):Void {
        var age = ++upd;
        if (age == 1 && opt != null && opt.position != null) {
            var rev = reversed;
            reversed = false;
            update(opt.position * duration);
            reversed = rev;
            if (stopped || Utils.noeq(age+1,upd))
                return;
            age = upd;
        }

        if (reversed)
            time = time * speed * -1;
        else
            time = time * speed;

        // Время не передано: (Если нет времени - ничего не может произойти, даже мгновение)
        if (Utils.isNaN(time) || Utils.eq(time, 0))
            return;

        // Пустой твин: (Забыли заполнить?)
        var len = a.length;
        if (Utils.eq(len, 0)) {
            if (bounce)
                reversed = !reversed;

            if (time > 0)
                ap = 1;
            else
                ap = 0;
            
            if (loop > 0)
                loop--;
            else if (Utils.eq(loop,0) && !stopped)
                removeTween(this);

            return;
        }

        // По очереди выполняем все задачи.
        //
        // Во время выполнения пользователь может повлиять на твинер, поэтому
        // на каждом шаге есть дополнительные условия:
        //   1. Если твин был поставлен на паузу, выполнение прекращается.
        //   2. Если был вызван метод update() повторно, выполнение прекращается.
        //   3. Если был достигнут предел действий для одного вызова MAX_CALL, выполнение прекращается.

        var limit = MAX_CALLS;
        while (limit-- != 0) {
            var act = a[ai];
            var p = ap + time;

            // Прогресс выполнения:
            if (p < 0) {
                // Задача выполнена. (Реверс)
                time += ap;
                ap = 0;
                executeAction(act, 0);

                // Внешняя отмена:
                if (stopped || Utils.noeq(age,upd))
                    return;

                // Достигнуто начало списка:
                if (Utils.eq(--ai,-1)) {
                    if (bounce) {
                        reversed = !reversed;
                        time *= -1;
                    }
                    if (Utils.eq(loop,0)) {
                        ai ++;
                        removeTween(this);
                        return;
                    }
                    if (loop > 0)
                        loop --;
                    ai ++;
                }
                else {
                    ap = Utils.eq(a[ai].duration,0)?1:a[ai].duration;
                }
            }
            else if (p >= act.duration && time > 0) {
                // Задача выполнена: (Норма)
                if (Utils.eq(act.duration, 0)) {
                    ap = 1;
                }
                else {
                    time -= (act.duration - ap);
                    ap = act.duration;
                }
                executeAction(act, 1);

                // Внешняя отмена:
                if (stopped || Utils.noeq(age,upd))
                    return;

                // Достигнут конец списка:
                if (Utils.eq(++ai,len)) {
                    if (Utils.eq(loop,0)) {
                        if (bounce) {
                            reversed = !reversed;
                            time *= -1;
                        }
                        ai --;
                        removeTween(this);
                        return;
                    }
                    if (loop > 0)
                        loop --;
                    if (bounce) {
                        reversed = !reversed;
                        time *= -1;
                        ai --;
                    }
                    else {
                        ai = 0;
                        ap = 0;
                    }
                }
                else {
                    ap = 0;
                }
            }
            else {
                // Задача выполняется:
                ap = p;
                executeAction(act, Utils.eq(act.duration,0)?0:(p/act.duration));
                return;
            }
        }

        #if debug
        // Слишком много вызовов:
        Browser.console.warn('Tween execute actions calls limit reached: ', this);
        #end
    }

    private function executeAction(action:Action, progress:Float):Void {
        if (Utils.eq(action.type, ActionType.EASE)) {
            var prop = null;
            Syntax.code('for ({0} in {1}) {', prop, action.props); // for in
                var v1 = action.cache[prop]; // Исходное значение
                var v2 = action.props[prop]; // Целевое значение

                if (Utils.isNumber(v2)) {
                    if (Utils.isUnd(v1)) {
                        v1 = target[prop];
                        if (Utils.isUnd(v1))
                            v1 = 0;
                        action.cache[prop] = v1;
                    }
                    target[prop] = v1 + action.ease(progress) * (v2 - v1);
                }
                else {
                    if (Utils.isUnd(v1)) {
                        v1 = target[prop];
                        if (Utils.isUnd(v1))
                            v1 = null;
                        action.cache[prop] = v1;
                    }  
                    target[prop] = Utils.eq(progress,1)?v2:v1;
                }
            Syntax.code('}'); // for end
            return;
        }
        if (Utils.eq(action.type, ActionType.CALL)) {
            if (Utils.eq(progress,1) && action.callback != null)
                Syntax.code('{0}.apply(null, {1})', action.callback, action.args);
            return;
        }
    }

    private function addAction(action:Action):Tween {
        if (Utils.eq(ai, -1)) {
            a[0] = action;
            ai = 0;
            ap = 0;
            action.prev = 0;
            duration = action.duration;
        }
        else {
            a.push(action);
            action.prev = duration;
            duration += action.duration;
        }
        return this;
    }

    /**
     * Получить строковое представление объекта.
     * @return Строковое представление этого объекта.
     */
    @:keep
    public function toString():String {
        return "[Tween target=" + Utils.str(target) + "]";
    }



    //////////////////
    //   ДЕЙСТВИЯ   //
    //////////////////

    /**
     * Добавить новую анимацию.
     * - Нулевая продолжительность анимации приведёт к мгновенной установке целевых значений.
     * - Числовые свойства будут анимированы от их текущих значений на момент анимирования.
     * - Нечисловые свойства будут установлены в конце указанной продолжительности.
     * 
     * Пример:
     * ```
     * Tween.get(target).to({x:120, alpha:0, visible:false}, 1000, Ease.elasticInOut);
     * ```
     * @param params Целевые значения свойств. Пример: `{ x:150, alpha:0, visible:false }`.
     * @param duration Продолжительность анимации в миллисекундах.
     * @param ease Функция анимации. По умолчанию: `Ease.linear`.
     * @return Этот экземпляр твина для удобного построения цепочки.
     */
    public function to(params:Dynamic, duration:Float = 0, ease:EaseFunction = null):Tween {
        if (!Utils.isNumber(duration) || !Utils.isFinite(duration) || duration < 0)
            return addAction({ type:ActionType.EASE, duration:0, props:params, ease:ease==null?Ease.linear:ease, cache:{} });

        return addAction({ type:ActionType.EASE, duration:duration, props:params, ease:ease==null?Ease.linear:ease, cache:{} });
    }

    /**
     * Добавить ожидание. (Пустую анимацию)
     * @param duration Продолжительность ожидания в миллисекундах.
     * @return Этот экземпляр твина для удобного построения цепочки.
     */
    public function wait(duration:Float):Tween {
        if (!Utils.isNumber(duration) || !Utils.isFinite(duration) || duration < 0)
            return addAction({ type:ActionType.WAIT, duration:0 });

        return addAction({ type:ActionType.WAIT, duration:duration });
    }

    /**
     * Добавить вызов произвольной функции.
     * @param callback Вызываемая функция.
     * @param args Передаваемые аргументы в функцию.
     * @return Этот экземпляр твина для удобного построения цепочки.
     */
    public function call(callback:Function, args:Array<Dynamic> = null):Tween {
        return addAction({ type:ActionType.CALL, duration:0, callback:callback, args:args });     
    }



    /////////////////
    //   СТАТИКА   //
    /////////////////

    static private var all:Dynamic = {}; // Target->[Tween, Tween, null, Tween, ...]
    static private var stamp:Float = 0;
    static private var intervalID:Int = -1;
    static private var steps:Int = 0;

    static private function addTween(tween:Tween):Void {
        var arr:Array<Tween> = all[tween.target];
        if (arr == null) {
            arr = [tween];
            tween.si = 0;
            all[tween.target] = arr;
        }
        else {
            tween.si = arr.length;
            arr[tween.si] = tween;
        }

        // Есть вероятность, что при добавлении этого твина уже
        // выполняется обновление прямо сейчас. С помощью этого
        // мы гарантируем обновление твина в следующем вызове step().
        tween.si = steps;

        if (Utils.eq(intervalID, -1) && interval > 0) {
            stamp = Utils.stamp();
            intervalID = Browser.window.setInterval(onInterval, interval);
        }
    }

    static private function removeTween(tween:Tween):Void {
        all[tween.target][tween.si] = null;
        tween.si = -1;
    }

    static private function onInterval():Void {
        var now = Utils.stamp();
        var dt = now - stamp;
        stamp = now;

        if (step(dt)) {
            Browser.window.clearInterval(intervalID);
            intervalID = -1;
        }
    }

    /**
     * Интервал обновления твинов. (mc)
     * 
     * Это значение используется для автоматического вызова `step()`.
     * Если задать `0` или меньше, автоматическое обновление не
     * будет использовано. В этом случае вы **должны** будете вызывать
     * метод `step()` самостоятельно. Это может быть полезно при
     * использовании библиотек, использующих собственный heartbeat.
     * 
     * По умолчанию: `16` (Примерно 60 раз в секунду)
     * 
     * @see setInterval: https://developer.mozilla.org/en-US/docs/Web/API/WindowOrWorkerGlobalScope/setInterval
     */
    static public var interval(default, set):Float = 16;
    static function set_interval(value:Float):Float {
        if (value == interval)
            return value;

        if (value > 0) {
            if (intervalID != -1) {
                Browser.window.clearInterval(intervalID);
                intervalID = Browser.window.setInterval(onInterval, value);
            }
            interval = value;
        }
        else {
            if (intervalID != -1) {
                Browser.window.clearInterval(intervalID);
                intervalID = -1;
            }
            interval = 0;
        }

        return value;
    }

    /**
     * Создать новый твиннер.
     * @param target Анимируемый объект.
     * @param params Параметры для нового твинера.
     * @return Новый твинер.
     */
    static public function get(target:Dynamic, params:TweenOptions = null):Tween {
        return new Tween(target, params);
    }

    /**
     * Проверить наличие активных твинов на указанном объекте.
     * - Возвращает `true`, если объект имеет хотя бы один активный твин в данный момент.
     * - Возвращает `false`, если передан `null` или объект не имеет твинов.
     * @param target Проверяемый объект.
     * @return Наличие твинов у объекта.
     */
    static public function has(target:Dynamic):Bool {
        var arr:Array<Tween> = all[target];
        if (arr == null)
            return false;

        var len = arr.length;
        while (len-- != 0) {
            if (arr[len] == null || arr[len].stopped)
                continue;
            return true;
        }
        return false;
    }

    /**
     * Остановить все активные твины на указанном объекте.
     * 
     * Вызов этого метода эквивалентен вызову `pause()` для каждого
     * отдельно взятого экземпляра `Tween`, целью которого является
     * указанный объект `target`.
     * 
     * @param target Анимированный объект.
     */
    static public function stop(target:Dynamic):Void {
        var arr:Array<Tween> = all[target];
        if (arr == null)
            return;

        var len = arr.length;
        while (len-- > 0) {
            if (arr[len] == null)
                continue;

            arr[len].si = -1;
        }
        Utils.delete(all[target]);
    }

    /**
     * Остановить воспроизведение всех твинов глобально.
     */
    static public function stopAll():Void {
        var key:Dynamic = null;
        Syntax.code('for({0} in {1}) {', key, all);
            var arr:Array<Tween> = all[key];
            var len = arr.length;
            while (len-- > 0) {
                if (arr[len] == null)
                    continue;
    
                arr[len].si = -1;
            }
        Syntax.code('}');
        all = {};
    }

    /**
     * Обновить анимацию всех твинов.
     * 
     * Этот метод вызывается автоматически через заданные промежутки
     * времени `interval`. (По умолчанию) Если интервал не задан, вы
     * должны самостоятельно вызывать этот метод. Этот метод должен 
     * вызываться обязательно, иначе может произойти утечка памяти
     * из за накопления незавершённых твинов.
     * 
     * @param time Прошедшее время. (mc)
     * @return Больше нет твинов для обновления.
     */
    static public function step(time:Float):Bool {
        steps ++;

        var target:Dynamic = null;
        var finish:Bool = true;
        Syntax.code('for ({0} in {1}) {', target, all); // for in
            var arr:Array<Tween> = all[target];
            var i = 0;
            var j = 0;
            while (i < arr.length) {
                var tween = arr[i++];

                // Пустая ячейка или не актуальный твин:
                if (tween == null || tween.stopped)
                    continue;

                // Пропуск новых твинов, добавленных в этом цикле обновления: (Обновятся на следующем)
                if (Utils.eq(tween.si, steps)) {
                    if (Utils.eq(tween.si, j)) {
                        j ++;
                    }
                    else {
                        tween.si = j;
                        arr[j++] = tween;
                    }
                    continue;
                }

                // Твиним:
                tween.update(time);
                if (tween.stopped)
                    continue;

                // Твин ещё не закончился:
                finish = false;
                if (Utils.eq(tween.si, j)) {
                    j ++;
                }
                else {
                    tween.si = j;
                    arr[j++] = tween;
                }
            }
            if (Utils.eq(j, 0))
                Utils.delete(all[target]);
            else if (Utils.noeq(j, i))
                arr.resize(j);
        Syntax.code('}'); // for end

        return finish;
    }
}

/**
 * Опций для нового твина.
 * 
 * Используется для передачи параметров новому экземпляру твина.
 */
typedef TweenOptions =
{
    /**
     * Смотрите описание этого свойства: `Tween.reversed`
     * 
     * По умолчанию: `false`
     */
    @:optional var reversed:Bool;

    /**
     * Смотрите описание этого свойства: `Tween.loop`
     * 
     * По умолчанию: `0` (Одно проигрывание)
     */
    @:optional var loop:Int;

    /**
     * Смотрите описание этого свойства: `Tween.bounce`
     * 
     * По умолчанию: `false`
     */
    @:optional var bounce:Bool;

    /**
     * Смотрите описание этого свойства: `Tween.speed`
     * 
     * По умолчанию: `1` (Обычная скорость)
     */
    @:optional var speed:Float;

    /**
     * Не проигрывать твин по умолчанию.
     * 
     * Передав `true` вы отключите автоматическое воспроизведение
     * твина сразу после его создания.
     * 
     * По умолчанию: `false` (Проигрывается)
     */
    @:optional var stopped:Bool;

    /**
     * Начальная позиция воспроизведения. (0-1)
     * 
     * Вы можете указать начальную позицию воспроизведения без
     * учёта циклов.
     * 
     * По умолчанию: `0` (Воспроизведение сначала)
     */
    @:optional var position:Float;

    /**
     * Удаление всех других активных твинов цели.
     * 
     * При передаче `true` удаляет с цели все другие авктивные
     * твины. Использование этого свойства аналогично вызову:
     * `Tween.stop(target)` перед созданием нового твина.
     * 
     * По умолчанию: `false` (Не удалять)
     */
    @:optional var clear:Bool;
}

/**
 * Описание действия выполняемого твинером.
 */
private typedef Action =
{
    /**
     * Тип действия.
     */
    var type:ActionType;

    /**
     * Продолжительность действия в миллисекундах.
     */
    var duration:Float;

    /**
     * Параметры для анимации.
     */
    @:optional var props:Dynamic;

    /**
     * Кеш для хранения параметров действия.
     * 
     * Используется твинером для запоминания начальных значений.
     */
    @:optional var cache:Dynamic;

    /**
     * Время выполнения всех предыдущих блоков. (mc)
     */
    @:optional var prev:Float;

    /**
     * Функция изинга.
     */
    @:optional var ease:EaseFunction;

    /**
     * Функция внешнего вызова.
     */
    @:optional var callback:Function;

    /**
     * Параметры для передачи в функцию внешнего вызова.
     */
    @:optional var args:Array<Dynamic>;
}

/**
 * Тип выполняемого действия.
 * 
 * Енум содержит перечисление всех возможных типов действий твинеров.
 */
private enum abstract ActionType(Int) to Int
{
    /**
     * Ожидание.
     */
    var WAIT = 0;

    /**
     * Изинг.
     */
    var EASE = 1;

    /**
     * Вызов внешней функции.
     */
    var CALL = 2;
}