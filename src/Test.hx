import haxe.xml.Fast;
import sys.io.File;
import sys.FileSystem;
import strafe.FileWrapper;
import strafe.emu.nes.NES;
import strafe.emu.nes.Palette;


class Test
{
	static inline var framesPerCycle = 30;
	static inline var maxCyclesWithoutChange = 20;

	static function main()
	{
		var testData = File.getContent("tests.xml");
		var fast = new Fast(Xml.parse(testData).firstElement());
		var romDir = fast.has.dir ? fast.att.dir : "assets/roms/test/";

		if (!FileSystem.exists("test_results"))
			FileSystem.createDirectory("test_results");
		else
		{
			for (file in FileSystem.readDirectory("test_results"))
				if (StringTools.endsWith(file, ".nes.png"))
					FileSystem.deleteFile("test_results/" + file);
		}

		var successes = 0;
		var failures:Array<String> = [];

		for (test in fast.nodes.test)
		{
			var rom = test.att.rom;
			var hash = test.has.hash ? test.att.hash : null;

			var nes = new NES();
			var f = FileWrapper.read(romDir + (StringTools.endsWith(romDir, "/") ? "" : "/") + rom);
			nes.loadGame(f);

			Sys.println(">> Running test " + rom + (hash == null ? " (NO HASH)" : "") + "...");
			var cycles = 0;
			var success = false;
			var currentHash = "";
			var lastHash = "";

			while (cycles < maxCyclesWithoutChange)
			{
				for (i in 0 ... framesPerCycle)
				{
					try
					{
						nes.frame(false);
					}
					catch(e:Dynamic)
					{
						Sys.println("ERROR: " + e);
						break;
					}
				}

				currentHash = haxe.crypto.Sha1.encode(Std.string(nes.ppu.bitmap));
				if (hash != null && currentHash == hash)
				{
					success = true;
					break;
				}
				else if (currentHash != lastHash)
				{
					lastHash = currentHash;
					cycles = 0;
				}
				++cycles;
			}

			if (success)
			{
				Sys.println("passed!");
				++successes;
			}
			else
			{
				Sys.println("FAILED!");
				Sys.println(currentHash);

				var resultImg = "test_results/" + rom + ".png";

				var bm = nes.ppu.bitmap;
				var bo = new haxe.io.BytesOutput();
				for (i in 0 ... 256 * 240)
				{
					var c = Palette.getColor(bm[i]);
					bo.writeByte((c & 0xFF0000) >> 16);
					bo.writeByte((c & 0xFF00) >> 8);
					bo.writeByte((c & 0xFF));
				}
				var bytes = bo.getBytes();
				var handle = sys.io.File.write(resultImg);
				new format.png.Writer(handle).write(format.png.Tools.buildRGB(256, 240, bytes));
				handle.close();

				Sys.println(resultImg);

				failures.push(rom);
			}
		}

		Sys.println("*** FINISHED ***");
		Sys.println("Succeeded:  " + successes);
		Sys.println("Failed:     " + failures.length);
		Sys.println(failures.join(', '));
	}
}
