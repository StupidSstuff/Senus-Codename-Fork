package funkin.game;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class RenderingDoneState extends MusicBeatState
{
	private var timeTaken:Float;

	public function new(timeTaken:Float)
	{
		super();
		this.timeTaken = timeTaken;
	}

	override public function create()
	{
		super.create();

		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		add(bg);

		var title = new FlxText(0, 110, FlxG.width, "Rendering Complete!", 52);
		title.setFormat(null, 52, FlxColor.WHITE, CENTER);
		add(title);

		var info = new FlxText(
			80, 220, FlxG.width - 160,
			"Song: " + PlayState.SONG.meta.name +
			"\n\nTime Taken: " + CoolUtil.timeToStr(timeTaken * 1000) +
			"\n\nOutput: " + SongRenderer.currentOutput +
			"\n\nPress ENTER to continue.",
			24
		);
		info.setFormat(null, 24, FlxColor.WHITE, CENTER);
		add(info);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.ACCEPT)
			PlayState.instance.nextSong();
	}
}
