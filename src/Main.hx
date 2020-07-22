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
        var obj = { x:0, y:0 };
        var box = Browser.document.createDivElement();
        box.style.background = "red";
        box.style.width = "50px";
        box.style.height = "50px";
        box.style.marginTop = obj.y + "px";
        box.style.marginLeft = obj.x + "px";
        Browser.document.body.appendChild(box);
        Browser.window.setInterval(function(){
            box.style.marginTop = obj.y + "px";
            box.style.marginLeft = obj.x + "px";
        }, 10);

        var tw = Tween.get(obj, { position:0.2, reversed:false }) 
            .to({x:500, y:0}, 1100, Ease.elasticInOut)
            .to({x:500, y:200}, 800, Ease.bounceOut)
            .to({x:100, y:100}, 700, Ease.circInOut)
            .call(function(a){ trace(a); }, ["FINISH!"]);
        tw.bounce = true;
        tw.loop = -1;
    }
}