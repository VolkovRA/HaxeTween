package;

import js.Browser;
import tween.Tween;
import tween.Ease;

/**
 * Пример.
 */
class Main 
{
    static function main() {
        // Dom element:
        var box = Browser.document.createDivElement();
        box.style.background = "red";
        box.style.width = "50px";
        box.style.height = "50px";
        box.style.marginTop = "10px";
        box.style.marginLeft = "10px";
        Browser.document.body.appendChild(box);

        var tw = Tween.get(box.style, { position:0.2, reversed:false, parse:true, modifier:function(v){ return v+"px"; }}) 
            .to({marginLeft:500, marginTop:0}, 1100, Ease.elasticInOut)
            .to({marginLeft:500, marginTop:200}, 800, Ease.bounceOut)
            .to({marginLeft:100, marginTop:100}, 700, Ease.circInOut)
            .call(function(a){ trace(a); }, ["FINISH!"]);
        tw.bounce = true;
        tw.loop = -1;

        // Haxe getter/setter:
        var ho = new HaxeObject();
        Tween.get(ho).to({ x:100 }, 1000);
    }
}

class HaxeObject
{
    private var _x:Int = 0;

    public function new(){
    }

    public var x(get, set):Int;
    function get_x():Int {
        return _x;
    }
    function set_x(value:Int):Int {
        _x = value;
        trace("Haxe setter x:", value);
        return value;
    }
}