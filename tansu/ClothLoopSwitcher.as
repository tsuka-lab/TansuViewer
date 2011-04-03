package tansu
{
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	public class ClothLoopSwitcher extends LoopSwitcher
	{
		public function ClothLoopSwitcher()
		{
			super();
		}
		
		protected override function createLoop(data:*):* {
			return new ClothLoop(data.outers, data.inners, data.bottoms);
		}
		
		public override function resize():void {
			for each (var loop:ClothLoop in this.loopTable) {
				loop.onResize();
			}
		}
		
		public override function startMove():void {
			for (var key:String in loopTable) {
				ClothLoop(loopTable[key]).startMove();
			}
		}
		
		protected override function setupKeyEvents():void {
			stage.addEventListener(KeyboardEvent.KEY_UP, function(keyEvent:KeyboardEvent):void {
				switch (keyEvent.keyCode) {
					case Keyboard.NUMPAD_1:
					case 49:
						ClothLoop(currentLoop()).switchOuterMoving();
						break;
					case Keyboard.NUMPAD_2:
					case 50:
						ClothLoop(currentLoop()).switchInnerMoving();
						break;
					case Keyboard.NUMPAD_3:
					case 51:
						ClothLoop(currentLoop()).switchBottomMoving();
						break;
				}
			});
		}
	}
}