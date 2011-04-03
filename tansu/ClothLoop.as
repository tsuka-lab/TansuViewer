package tansu
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;

	//
	// アウター・インナー・ボトムの3段のループをまとめたもの
	//
	public class ClothLoop extends Sprite
	{
		private var outerLoop:Loop;
		private var innerLoop:Loop;
		private var bottomLoop:Loop;
		
		private var topCenterMark:Shape;
		private var bottomCenterMark:Shape;
		
		private const topMargin:uint = 16;
		private const bottomMargin:uint = 16;
		private const space:uint = 3; // ループ間の隙間
		
		public function ClothLoop(outers:Array, inners:Array, bottoms:Array)
		{
			super();
			
			var h:uint = (600 - topMargin - bottomMargin - space*2) / 3; // 各ループの高さ
			
			// フォーカス用三角
			drawCenterMark();
			
			// 起動時のI/Oの負荷を軽減するため順に追加していく
			outerLoop = addLoop(outers, topMargin, h, function():void {
				trace("outer done");
				innerLoop = addLoop(inners, topMargin+h+space, h, function():void {
					trace("inner done");
					bottomLoop = addLoop(bottoms, topMargin + h*2 + space*2, h, function():void {
						trace("bottom done");
						dispatchEvent(new Event("loaded"));
					});
				});
			});
		}
		
		private function drawCenterMark():void {
			this.topCenterMark = new Shape();
			this.bottomCenterMark = new Shape();
			
			var w:uint = 16;
			var h:uint = 10;
			
			// draw top
			var g:Graphics = topCenterMark.graphics;
			g.beginFill(0xFFFFFF);
			g.moveTo(0, h);
			g.lineTo(w/2, 0);
			g.lineTo(-w/2, 0);
			g.lineTo(0, h);
			g.endFill();
			// draw bottom
			g = bottomCenterMark.graphics;
			g.beginFill(0xFFFFFF);
			g.moveTo(0, -h);
			g.lineTo(w/2, 0);
			g.lineTo(-w/2, 0);
			g.lineTo(0, -h);
			g.endFill();

			addChild(topCenterMark);
			addChild(bottomCenterMark);
			
			// centerize
			addEventListener(Event.ADDED_TO_STAGE, function():void {
				stage.addEventListener(Event.RESIZE, function():void {
					onResize();
				});
				onResize();
			});
		}
		
		public function onResize():void {
			// 三角
			var c:uint = stage.stageWidth/2;
			topCenterMark.x = c;
			topCenterMark.y = 0;
			bottomCenterMark.x = c;
			bottomCenterMark.y = stage.stageHeight;
			
			if (outerLoop && innerLoop && bottomLoop) {
				var h:uint = (stage.stageHeight - topMargin - bottomMargin - space*2) / 3; // 各ループの高さ
				outerLoop.setHeight(h);
				innerLoop.setHeight(h);
				bottomLoop.setHeight(h);
				outerLoop.y = topMargin;
				innerLoop.y = topMargin + h + space;
				bottomLoop.y = topMargin + h*2 + space*2;
			}
			
		}
		
		private function addLoop(pathes:Array, top:int, h:uint, after:Function=null):Loop {
			var loop:Loop = new Loop(pathes, h);
			loop.y = top;
			loop.addEventListener("loaded", function():void {
				trace(" finish loop");
				addChild(loop);
				if (after != null) {
					after.apply(this);
				}
			});
			return loop;
		}
		
		public function startMove():void {
			outerLoop.startMoveLeft();
			innerLoop.startMoveRight();
			bottomLoop.startMoveLeft();
		}
		
		public function switchOuterMoving():void {
			outerLoop.switchMoving();
		}
		public function switchInnerMoving():void {
			innerLoop.switchMoving();
		}
		public function switchBottomMoving():void {
			bottomLoop.switchMoving();
		}
	}
}