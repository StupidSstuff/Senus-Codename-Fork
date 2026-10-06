package funkin.game;

import flixel.FlxG;
import haxe.io.Bytes;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageFileFormat;
import openfl.system.System;

#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

class SongRenderer
{
	public static var active:Bool = false;
	public static var frameCaptured:Int = 0;
	public static var startTime:Float = 0;
	public static var currentSong:String = "";
	public static var currentOutput:String = "";

	#if sys
	private static var process:Process = null;
	private static var image:Image = null;
	private static var captureAccumulator:Float = 0;
	private static var gcAccumulator:Float = 0;
	private static var oldFixedTimestep:Bool = false;
	private static var oldAnimationTimeScale:Float = 1;
	private static var oldUpdateFramerate:Int = 60;
	private static var oldDrawFramerate:Int = 60;
	private static var oldAutoPause:Bool = true;
	#end

	public static function start(songName:String):Bool
	{
		if (active) return true;

		#if FFMPEG_RENDERER
		#if sys
		currentSong = new haxe.io.Path(songName).file;
		frameCaptured = 0;
		captureAccumulator = 0;
		gcAccumulator = 0;
		oldFixedTimestep = FlxG.fixedTimestep;
		oldAnimationTimeScale = FlxG.animationTimeScale;
		oldUpdateFramerate = FlxG.updateFramerate;
		oldDrawFramerate = FlxG.drawFramerate;
		oldAutoPause = FlxG.autoPause;
		startTime = haxe.Timer.stamp();

		var renderPath = normalizePath(Options.renderPath);
		if (!renderPath.endsWith("/")) renderPath += "/";

		if (!ensureDirectory(renderPath)) return false;

		if (Options.targetFPS <= 0) Options.targetFPS = 60;

		if (Options.oldFFmpegMode)
		{
			currentOutput = renderPath + currentSong + "/";
			if (!ensureDirectory(currentOutput)) return false;

			active = true;
			configureTiming();
			trace("Song Renderer: Classic screenshot mode -> " + currentOutput);
			return true;
		}

		#if windows
		if (!FileSystem.exists("ffmpeg.exe"))
		{
			trace("Song Renderer: ffmpeg.exe not found beside the game executable.");
			return false;
		}
		#end

		final width = Application.current.window.width;
		final height = Application.current.window.height;

		currentOutput = renderPath + currentSong + ".mp4";
		if (FileSystem.exists(currentOutput))
			currentOutput = renderPath + currentSong + "-" + DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S") + ".mp4";

		try
		{
			process = new Process("ffmpeg", [
				"-loglevel", "quiet",
				"-y",
				"-f", "rawvideo",
				"-pix_fmt", "rgba",
				"-s", width + "x" + height,
				"-r", Std.string(Options.targetFPS),
				"-i", "-",
				"-c:v", Options.vidEncoder,
				"-b:v", Std.string(Std.int(Options.renderBitrate * 1000000)),
				"-pix_fmt", "yuv420p",
				currentOutput
			]);
		}
		catch (e:Dynamic)
		{
			trace("Song Renderer: failed to start FFmpeg: " + Std.string(e));
			process = null;
			return false;
		}

		active = true;
		configureTiming();
		trace("Song Renderer: FFmpeg mode -> " + currentOutput);
		return true;
		#else
		trace("Song Renderer: unavailable on this target.");
		return false;
		#end
		#else
		return false;
		#end
	}

	private static function configureTiming():Void
	{
		#if sys
		FlxG.fixedTimestep = true;
		FlxG.animationTimeScale = Options.framerate / Math.max(1, Options.targetFPS);

		// Rendering must advance at the video's actual frame rate.
		// Do not allow the normal "unlocked FPS" setting to make the
		// gameplay clock run faster than the video.
		final fps:Int = Std.int(Math.max(1, Math.round(Options.targetFPS)));
		FlxG.updateFramerate = fps;
		FlxG.drawFramerate = fps;

		FlxG.autoPause = false;
		#end
	}

	public static function captureFrame():Void
	{
		#if FFMPEG_RENDERER
		#if sys
		if (!active) return;

		final videoFPS = Math.max(1, Options.targetFPS);
		if (Options.unlockFPS)
		{
			captureAccumulator += 1 / Math.max(1, FlxG.drawFramerate);
			if (captureAccumulator + 0.000001 < 1 / videoFPS)
				return;
			captureAccumulator = 0;
		}

		try
		{
			image = Application.current.window.readPixels();
			if (image == null) return;

			if (Options.oldFFmpegMode)
			{
				final ext = Options.lossless ? ".png" : ".jpg";
				final filename = currentOutput + Std.string(frameCaptured).addZeros(7) + ext;
				final bytes:Bytes = image.encode(Options.lossless ? ImageFileFormat.PNG : ImageFileFormat.JPEG, Options.renderQuality);
				if (bytes != null)
				{
					File.saveBytes(filename, bytes);
					frameCaptured++;
				}
			}
			else if (process != null && process.stdin != null)
			{
				final bytes:Bytes = image.getPixels(new lime.math.Rectangle(0, 0, image.width, image.height));
				process.stdin.writeBytes(bytes, 0, bytes.length);
				frameCaptured++;
			}

			gcAccumulator += 1 / videoFPS;
			if (Options.renderGCRate > 0 && gcAccumulator >= Options.renderGCRate)
			{
				gcAccumulator = 0;
				System.gc();
			}
		}
		catch (e:Dynamic)
		{
			trace("Song Renderer: frame capture error: " + Std.string(e));
		}
		#end
		#end
	}

	public static function stop():Float
	{
		final elapsed = active ? haxe.Timer.stamp() - startTime : 0;

		#if FFMPEG_RENDERER
		#if sys
		try
		{
			if (process != null)
			{
				if (process.stdin != null) process.stdin.close();
				process.close();
				process.kill();
			}
		}
		catch (e:Dynamic)
		{
			trace("Song Renderer: stop error: " + Std.string(e));
		}

		process = null;

		FlxG.fixedTimestep = oldFixedTimestep;
		FlxG.animationTimeScale = oldAnimationTimeScale;
		FlxG.updateFramerate = oldUpdateFramerate;
		FlxG.drawFramerate = oldDrawFramerate;
		FlxG.autoPause = oldAutoPause;
		#end
		#end

		active = false;
		return elapsed;
	}

	private static function normalizePath(path:String):String
	{
		return path.split("\\").join("/");
	}

	#if sys
	private static function ensureDirectory(path:String):Bool
	{
		try
		{
			if (FileSystem.exists(path))
				return FileSystem.isDirectory(path);

			FileSystem.createDirectory(path);
			return FileSystem.exists(path) && FileSystem.isDirectory(path);
		}
		catch (e:Dynamic)
		{
			trace("Song Renderer: directory error: " + Std.string(e));
			return false;
		}
	}
	#end
}
