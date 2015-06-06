package strafe;

import haxe.io.Input;


interface IEmulator
{
	// load a game and start emulation
	public function loadGame(gameData:FileWrapper):Void;

	// reset the currently running game
	public function reset():Void;

	// add a new controller to a specific port or the first empty port
	public function addController(c:IController, ?port:Int=null):Null<Int>;

	// called once per frame
	public function frame(?render:Bool=true):Void;
}
