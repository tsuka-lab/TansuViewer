package tansu
{
	import caurina.transitions.*;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.*;

	public class Loop extends Sprite
	{
		private var moving:Boolean = false;
		private var movingLeft:Boolean = true;
		private var moveTimeoutId:uint;
		
		private var speed:uint = 9;
		private var leftList:ImageList;
		private var rightList:ImageList;
		
		public function Loop(pathes:Array, h:uint)
		{
			super();
			
			trace(" start loop");
			
			// listB用のコピー
			////var pathes2:Array = this.copyStrArray(pathes);
			
			var listA:ImageList = new ImageList();
			
			listA.addEventListener("loaded", function():void {
				trace(" A loaded");
				addChild(listA);
				// 続いてBを複製する
				var listB:ImageList = listA.clone();
				listB.x = listA.x + listA.width;
				addChild(listB);
				trace(" B loaded");
				
				leftList = listA;
				rightList = listB;
				dispatchEvent(new Event("loaded"));
			});
			listA.load(pathes, h);
			
			// キーイベント (スピードの上下)
			setupKeyEvents();
		}
		
		private function setupKeyEvents():void {
			this.addEventListener(Event.ADDED_TO_STAGE, function():void {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, function(keyEvent:KeyboardEvent):void {
					switch (keyEvent.keyCode) {
						case Keyboard.UP:
							increaseSpeed();
							break;
						case Keyboard.DOWN:
							decreaseSpeed();
							break;
					}
				});
			});
		}
		
		public function setHeight(h:Number):void {
			if (leftList) {
				leftList.setHeight(h);
			}
			if (rightList) {
				rightList.setHeight(h);
			}
			rightList.x = leftList.x + leftList.width;
		}
		
		private function copyStrArray(ary:Array):Array {
			var newArray:Array = [];
			for each (var item:String in ary) {
				newArray.push(item);
			}
			return newArray;
		}
		
		public function startMoveLeft():void {
			stop();
			this.moving = true;
			this.movingLeft = true;
			moveLeft();
		}
		
		public function startMoveRight():void {
			stop();
			this.moving = true;
			this.movingLeft = false;
			moveRight();
		}
		
		private function moveLeft():void {
			if (!moving) return;
			leftList.x -= speed;
			rightList.x = leftList.x + leftList.width;
			// 通りすぎたらleftListとrightListを切り替え
			if (rightList.x < 0) {
				// 左側のリストを右に移動
				leftList.x = rightList.x + rightList.width;
				
				// 入れ替え
				var tmp:ImageList = leftList;
				leftList = rightList;
				rightList = tmp;
			}
			this.moveTimeoutId = setTimeout(moveLeft, 10);
		}
		
		private function moveRight():void {
			if (!moving) return;
			leftList.x += speed;
			rightList.x = leftList.x + leftList.width;
			
			if (rightList.x > stage.stageWidth) {
				rightList.x = leftList.x - rightList.width; // 右側にあったリストを左に移動しておく
				
				var tmp:ImageList = leftList;
				leftList = rightList;
				rightList = tmp;
			}
			this.moveTimeoutId = setTimeout(moveRight, 10);
		}
		
		public function stop():void {
			cancelTweens();
			if (!moving) return;
			this.moving = false;
			clearTimeout(this.moveTimeoutId);
		}
		
		public function cancelTweens():void {
			Tweener.removeTweens(leftList);
			Tweener.removeTweens(rightList);
		}
		
		public function slowDown():void {
			stop();
			
			var center:Number = stage.stageWidth/2;
			
			// 現在中央にあるリスト
			var centerList:ImageList = null
			if (leftList.x <= center
				&& leftList.x + leftList.width >= center) {
				centerList = leftList;
			} else if (rightList.x <= center
				&& rightList.x + rightList.width >= center) {
				centerList = rightList;
			} else {
				return; // 中央に何もない
			}
			
			// さらにそのリストの中で中央にある絵
			var d1:Number = center - centerList.x;
			var img:Bitmap = centerList.getImageAt(d1);
			// 補正幅 (あとどれだけ移動すれば良いか)
			var d2:Number = img.x + img.width/2;
			var dx:Number = d1 - d2;
			
			// 移動
			Tweener.addTween(leftList, {
				x: leftList.x + dx,
				transition: "easeOutCubic",
				time: 1
			});
			Tweener.addTween(rightList, {
				x: rightList.x + dx,
				transition: "easeOutCubic",
				time: 1
			});
		}
		
		public function increaseSpeed():void {
			var d:uint = 2;
			var max:uint = 100;
			var newSpeed:uint = this.speed + d;
			if (newSpeed > max) {
				this.speed = max;
			} else {
				this.speed = newSpeed;
			}
		}
		public function decreaseSpeed():void {
			var d:uint = 2;
			var min:uint = 1;
			var newSpeed:int = this.speed - d;
			if (newSpeed < min) {
				this.speed = min;
			} else {
				this.speed = newSpeed;
			}
		}
		
		public function switchMoving():void {
			if (moving) {
				slowDown();
			} else {
				if (movingLeft) {
					startMoveLeft();
				} else {
					startMoveRight();
				}
			}
		}
	}
}