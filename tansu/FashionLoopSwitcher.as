package tansu
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	public class FashionLoopSwitcher extends LoopSwitcher
	{
		public function FashionLoopSwitcher()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, function():void {
				stage.addEventListener(Event.RESIZE, function():void {
					resize();
				});
				resize();
			});
		}
		
		public override function resize():void {
			for each (var loop:Loop in this.loopTable) {
				loop.setHeight(stage.stageHeight);
			}
		}
		
		protected override function createLoop(pathData:*):* {
			return new Loop(pathData, 600);
		}
		
		public override function startMove():void {
			for (var key:String in loopTable) {
				Loop(loopTable[key]).startMoveLeft();
			}
		}
		
		protected override function setupKeyEvents():void {
			stage.addEventListener(KeyboardEvent.KEY_UP, function(keyEvent:KeyboardEvent):void {
				switch (keyEvent.keyCode) {
					case Keyboard.NUMPAD_4:
					case 52:
						Loop(currentLoop()).switchMoving();
						break;
				}
			});
		}
	}
}