#!/usr/bin/env python3
"""NEON-CASTER - music/daw.py: the arrangements out to Renoise and Bitwig, and back.

Each track's NAME.arr (arrange.py) is its bars, its clips and the order they
play in. This writes that as a song a DAW opens - every clip there to play,
rearrange or launch live - and reads the edited song back into the .arr, so
arrange.py --render (and the game's arranger) plays what was made there.

    ~/.venvs/music/bin/python daw.py --xrns [NAME ...]               # -> ~/Music/NEON-CASTER/daw/renoise/NAME.xrns
    ~/.venvs/music/bin/python daw.py --from-xrns FILE [NAME]         # an edited song back to music/NAME.arr
    ~/.venvs/music/bin/python daw.py --dawproject [NAME ...]         # -> ~/Music/NEON-CASTER/daw/bitwig/NAME.dawproject
    ~/.venvs/music/bin/python daw.py --from-dawproject FILE [NAME]   # back to the .arr
    ... --out FILE      (with --from-*) write the .arr there instead of music/NAME.arr
    ... --dir FOLDER    (with --xrns / --dawproject) write the songs there instead

No names: all of them (arrange.tracks()). NAME left off --from-*: the file's
name (level1.xrns -> level1). Both read the audio the bars are counted on,
music/edit/NAME.flac (arrange.py --sources writes it), and put it in the song.

RENOISE (.xrns: a zip of Song.xml and the sample). One instrument, the
source, sliced at every bar line: a bar is a note (bar 1 is C-4, bar 2 C#4...
in every track; the slices are named "bar N", and any lead-in before bar 1 is
a slice of its own on B-3). A clip finer than a bar (the game's arranger cuts to
a 128th: "clip J at 17.25-17.5") adds a slice at each edge between bar lines
("bar 17.25"), so a clip is still whole slices. One pattern per clip, named
after it ("F peak"): 16 lines a bar (LPB 4; 32, LPB 8, when a clip's edge is
finer than a 16th), each slice's note on its line (an edge finer than a 32nd
played late by the line's delay column). A note plays its slice to
the next note or its slice's end, and the import reads them back that way.
The pattern sequence is the arrangement, each entry a section named after its
clip ("F peak x2" over a repeat), so the sequence reads as the .arr does.
Clips the arrangement doesn't use come after it, in a section called CLIPS
(the import stops there): every clip is a pattern to schedule live from the
matrix. The tempo is the .arr's, fractions and all (Renoise keeps them); and
as every bar is its own note, any drift starts again at each bar line.

Reading one back: the sequence (up to CLIPS) is the arrangement, the same
pattern N times in a row a CLIP*N. A pattern's notes are bars, in line order;
each run of bars one after another is a clip - the clip it was (the pattern's
name first, else any clip with those bars) or a new one, named on from the
letters. bpm, offset, bars, tail, source and seams stay the .arr's; auto no.

BITWIG (.dawproject: the open format - a zip of project.xml, metadata.xml and
the audio). One audio track. The arrangement: a clip per entry (a repeat is
the clip again, end to end), each its bars of the source (warped at the .arr's
tempo: played as is), with a cue marker at each entry named after its clip.
The clip launcher: one scene per clip (the arrangement's order first, then any
it doesn't use), each scene that clip in the track's slot, looping on exactly
its bars - launch a scene, or the slot. Each clip is coloured as its pad in the
game's arranger, and its copies in the arrangement with it.
With the track's stems (soundmon's stems.py, in ~/Music/NEON-CASTER/samples/
NAME - TITLE: each part as long as the take and lined up with it to the
sample) every stem is a track too, with the take's clips in the arrangement
and the launcher, in group tracks as the parts add up: STEMS (drums, bass,
synths + fx, vocals - they sum to the take, so they play and the take is
muted, kept to compare) and the finer splits of the same sound, muted: DRUMS
SPLIT, SYNTHS BY RANGE, SYNTHS BY KIND, SYNTHS DRY + REVERB. The stems are
read where they are (external files), not copied in. The one-shots as
sampler instruments (.multisample: soundmon's instruments.py) are in the
folder's 5 Instruments/ - DAWproject can't hold Bitwig's own devices.
Reading one back: the take's own track (named NAME), else the one with the
most clips: its arrangement clips in time
order, each placed back on bars by where it starts in the source and how long
it is (a looped clip longer than its loop is that clip repeated); named as
for Renoise, by the clip's name first.

PATTERNS (the arrangement's "pattern A1  C*2 B" lines): a pattern's block goes
across as its clips, one after another; the first entry's section (Renoise) or
marker (Bitwig) is named "[A1] C peak", the rest "(A1) B groove". Read back,
those make the pattern again (its first play says what it is; a later play
that differs comes back as its clips).

NAME can be NAME/ALT, an alternative arrangement (music/arrangements/NAME/
ALT.arr): its songs are NAME-ALT.xrns / .dawproject, with NAME's audio.

(needs numpy and soundfile: the music venv - see arrange.py)
"""
import io, os, re, sys, zipfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import arrange

OUT = os.path.expanduser("~/Music/NEON-CASTER/daw")
NOTE_NAMES = ["C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"]
FIRST_SLICE = 48          # C-4: bar 1's note (the slices go up from the whole sample's note, as Renoise lays them out)
LPB = 4                   # lines a beat
BAR_LINES = 4 * LPB       # lines a bar
STEPS = 128              # the game's arranger's finest step: a 128th of a bar
CLIPS_SECTION = "CLIPS"   # the Renoise sequence's spare clips (not the arrangement) start a section of this name


# --- COMMON -----------------------------------------------------------------
def source_flac(name):
    p = os.path.join(HERE, "edit", name + ".flac")
    if not os.path.exists(p):
        raise SystemExit("%s: no %s - run arrange.py --sources %s first" % (name, p, name))
    return p


def bar_len(A):
    return 240.0 / A["bpm"]


def bar_start(A, b):
    """Where bar b (1-based) starts in the source, in seconds."""
    return A["offset"] + (b - 1) * bar_len(A)


def label(clip):
    c, a, b, kind = clip
    return ("%s %s" % (c, kind)).strip()


# the game arranger's clip colours (ArCol~&, EDITOR/ARRANGER.BM), by the clip's place in the .arr
CLIP_COLOURS = ["#ff5ac8", "#5ae6ff", "#ffdc5a", "#78ff8c", "#ff8c3c", "#aa78ff",
                "#ff646e", "#5aaaff", "#c8ff5a", "#ffaadc", "#64ffdc", "#e6e6e6"]


def clip_colour(A, clip):
    k = [c[0] for c in A["clips"]].index(clip[0])
    return CLIP_COLOURS[k % len(CLIP_COLOURS)]


def used_order(A):
    """The clips in the order the arrangement first plays them (in its patterns too), then the ones it doesn't."""
    seen = []
    for c, r, p, first in arrange.flat(A)[0]:
        if c not in seen: seen.append(c)
    for c, a, b, k in A["clips"]:
        if c not in seen: seen.append(c)
    by = {c[0]: c for c in A["clips"]}
    return [by[c] for c in seen if c in by]


def runs_of_pieces(pieces):
    """Pieces of the source in play order [(from, to)] -> runs: a piece starting where the one
    before it ended carries a run on."""
    runs = []
    for a, e in pieces:
        if runs and abs(a - runs[-1][1]) < 1e-6: runs[-1] = (runs[-1][0], e)
        else: runs.append((a, e))
    return runs


class Namer:
    """Names runs of bars as clips: the hinted clip if it's exactly those bars, else any clip
    that is, else a new one (the first free letter, its kind the clip its first bar is in)."""
    def __init__(self, A):
        self.clips = list(A["clips"])

    def name(self, a, b, hint=None):
        for c in self.clips:
            if c[0] == hint and (c[1], c[2]) == (a, b): return c[0]
        for c in self.clips:
            if (c[1], c[2]) == (a, b): return c[0]
        have = {c[0] for c in self.clips}
        free = [x for x in arrange.CLIP_NAMES if x not in have]
        n = free[0] if free else next("Z%d" % k for k in range(len(self.clips), 999) if "Z%d" % k not in have)
        kind = next((c[3] for c in self.clips if c[1] <= a <= c[2]), "")
        self.clips.append((n, a, b, kind))
        return n


def collapse(names):
    seq = []
    for c in names:
        if seq and seq[-1][0] == c: seq[-1] = (c, seq[-1][1] + 1)
        else: seq.append((c, 1))
    return seq


LOOP_MARK = "|"      # a section (Renoise) or marker (Bitwig) named "| ..." is where the loop starts: what's before it is an intro
# A pattern's play (A1: the game arranger's little arrangement of clips, one block in the
# arrangement): its first clip's section or marker is named "[A1] C peak", the rest "(A1) B groove"


def pattern_prefix(pat, first):
    return ("[%s] " if first else "(%s) ") % pat if pat else ""


def entry_label(clip, r, pat, first, loop):
    """A section's (Renoise) or marker's (Bitwig) name for an entry of the arrangement opened out."""
    n = pattern_prefix(pat, first) + label(clip) + (" x%d" % r if r > 1 else "")
    return LOOP_MARK + " " + n if loop else n


class Groups:
    """Reading names back: which pattern's play an entry is in - None, or (pattern, its play's number)."""
    def __init__(self): self.n, self.now = 0, None
    def at(self, name):
        n = (name or "").strip()
        if n.startswith(LOOP_MARK): n = n[len(LOOP_MARK):].strip()
        m = re.match(r"^([\[(])([A-F][1-9])[\])]", n)
        if not m: self.now = None; return None
        if m.group(1) == "[" or self.now is None or self.now[0] != m.group(2):
            self.n += 1; self.now = (m.group(2), self.n)
        return self.now


def tokens_of(order, groups, pats):
    """Clips played in order (and the pattern's play each is in) -> the arrangement's entries: a
    pattern's play is the pattern (the first play of it says what it is; a later one that differs
    goes in as its clips), and repeats run together (C*3, A1*2)."""
    out, i = [], 0
    while i < len(order):
        g = groups[i] if groups else None
        if g is None:
            out.append(order[i]); i += 1; continue
        j = i
        while j < len(order) and groups[j] == g: j += 1
        content = collapse(order[i:j])
        if g[0] not in pats: pats[g[0]] = content
        if pats[g[0]] == content: out.append(g[0])
        else: out.extend(order[i:j])
        i = j
    return collapse(out)


def finish(name, A, clips, order, out=None, loop_i=None, groups=None):
    """The .arr with the DAW's clips and arrangement (the rest kept), auto no - written to out
    (or music/NAME.arr). loop_i: the play the loop starts on (after an intro), if one was marked;
    groups: the pattern's play each play is in (None: none), so the patterns come back."""
    if not order:
        raise SystemExit("%s: the song plays no bars - nothing to arrange" % name)
    B = dict(A)
    B["clips"], B["auto"] = clips, False
    groups = groups or [None] * len(order)
    pats = {}
    if loop_i and 0 < loop_i < len(order):
        intro = tokens_of(order[:loop_i], groups[:loop_i], pats)
        B["arrange"], B["loop"] = intro + tokens_of(order[loop_i:], groups[loop_i:], pats), len(intro)
    else:
        B["arrange"], B["loop"] = tokens_of(order, groups, pats), 0
    B["patterns"] = dict(A.get("patterns", {}))       # (any the song doesn't play are kept)
    B["patterns"].update(pats)
    if out:
        keep = arrange.arr_path
        arrange.arr_path = lambda n: out
        try: arrange.write_arr(name, B)
        finally: arrange.arr_path = keep
    else:
        arrange.write_arr(name, B)
    return B


def summary(name, A, path):
    return arrange.summary(name, A) + "  -> " + path


def name_from(path):
    return re.sub(r"\.(xrns|dawproject)$", "", os.path.basename(path), flags=re.I)


# --- RENOISE ----------------------------------------------------------------
def note_name(n):
    return "%s%d" % (NOTE_NAMES[n % 12], n // 12)


def note_number(s):
    s = (s or "").strip().upper()
    for i, nn in enumerate(NOTE_NAMES):
        if s[:2] == nn and s[2:].isdigit(): return i + 12 * int(s[2:])
    return None


def clip_edges(A):
    """Clip starts and ends between bar lines (a clip finer than a bar - the game's arranger cuts to a 128th)."""
    E = set()
    for c, a, b, k in A["clips"]:
        for x in (a, b + 1):
            if not arrange.whole(x) and x > 1: E.add(x)
    return sorted(E)


def lpb_for(A):
    """Lines a beat: 4 (a line a 16th), or 8 when a clip's edge is finer than a 16th (finer than a
    32nd: a note's delay puts it between lines - 256ths of one)."""
    return LPB if all(arrange.whole(x * 4 * LPB) for x in clip_edges(A)) else 2 * LPB


def slices(A, frames, sr):
    """The slice markers (sample positions) and each slice's bar place (0: the lead-in before bar 1):
    one a bar, and one more at each clip edge between bar lines - so every clip is whole slices."""
    pos, bars = [], []
    if A["offset"] >= 0.01:                              # more than 10 ms before bar 1: a lead-in slice
        pos.append(0); bars.append(0)
    for b in sorted(set(range(1, A["bars"] + 1)) | set(clip_edges(A))):
        p = max(0, int(round(bar_start(A, b) * sr))) if pos else 0     # the first slice starts the sample (Renoise's way)
        if p >= frames: break
        if pos and p <= pos[-1]: continue
        pos.append(p); bars.append(b)
    return pos, bars


def xml_sample(name, note_lo, note_hi, base, length, markers=None, alias=False):
    L = ["<Sample>", "<Name>%s</Name>" % escape(name), "<Volume>1.0</Volume>", "<Panning>0.5</Panning>",
         "<Transpose>0</Transpose>", "<Finetune>0</Finetune>", "<BeatSyncIsActive>false</BeatSyncIsActive>",
         "<OneShotTrigger>false</OneShotTrigger>", "<NewNoteAction>Cut</NewNoteAction>",
         "<InterpolationMode>Cubic</InterpolationMode>", "<AutoSeek>false</AutoSeek>", "<AutoFade>false</AutoFade>",
         "<LoopMode>Off</LoopMode>", "<LoopStart>0</LoopStart>", "<LoopEnd>%d</LoopEnd>" % length]
    if markers is not None:
        L.append("<SliceMarkers>" + "".join("<SliceMarker><SamplePosition>%d</SamplePosition></SliceMarker>" % p
                                            for p in markers) + "</SliceMarkers>")
    L += ["<SingleSliceTriggerEnabled>true</SingleSliceTriggerEnabled>",
          "<IsAlias>%s</IsAlias>" % ("true" if alias else "false"),
          "<Mapping><Layer>Note-On Layer</Layer><BaseNote>%d</BaseNote><NoteStart>%d</NoteStart><NoteEnd>%d</NoteEnd>"
          "<MapKeyToPitch>true</MapKeyToPitch><VelocityStart>0</VelocityStart><VelocityEnd>127</VelocityEnd>"
          "<MapVelocityToVolume>true</MapVelocityToVolume></Mapping>" % (base, note_lo, note_hi),
          "<DisplayStart>0</DisplayStart><DisplayLength>%d</DisplayLength>" % length, "</Sample>"]
    return "".join(L)


def xml_track_devices(master, bpm=None, lpb=LPB):
    if master:
        return ("<FilterDevices><Devices><MasterTrackMixerDevice type=\"MasterTrackMixerDevice\">"
                "<IsActive><Value>1.0</Value></IsActive><Panning><Value>0.5</Value></Panning>"
                "<Volume><Value>1.0</Value></Volume><PostPanning><Value>0.5</Value></PostPanning>"
                "<PostVolume><Value>1.0</Value></PostVolume>"
                "<BpmAutomator><Value>%s</Value></BpmAutomator><LpbAutomator><Value>%d</Value></LpbAutomator>"
                "<TplAutomator><Value>12</Value></TplAutomator>"
                "</MasterTrackMixerDevice></Devices></FilterDevices>" % (fmt(bpm), lpb))
    return ("<FilterDevices><Devices><TrackMixerDevice type=\"TrackMixerDevice\">"
            "<IsActive><Value>1.0</Value></IsActive><Panning><Value>0.5</Value></Panning>"
            "<Volume><Value>1.0</Value></Volume><PostPanning><Value>0.5</Value></PostPanning>"
            "<PostVolume><Value>1.0</Value></PostVolume>"
            "</TrackMixerDevice></Devices></FilterDevices>")


def fmt(x):
    return ("%.6f" % x).rstrip("0").rstrip(".")


def song_xml(name, A, frames, sr, sample_file):
    pos, sbars = slices(A, frames, sr)
    lpb = lpb_for(A)
    BL = 4 * lpb                                                       # lines a bar
    base = FIRST_SLICE - 1 - (1 if sbars and sbars[0] == 0 else 0)     # bar 1 is always C-4: a lead-in goes on B-3
    note_of = {b: base + 1 + k for k, b in enumerate(sbars)}
    ends = pos[1:] + [frames]
    # the instrument: the whole source on the note below the slices, a slice a bar from C-4 up
    samples = [xml_sample(name, base, base, base, frames, markers=pos)]
    for k, b in enumerate(sbars):
        n = base + 1 + k
        samples.append(xml_sample("%s %s [%s]" % (name, "lead-in" if b == 0 else "bar %s" % arrange.bar_dec(b), note_name(n)),
                                  n, n, n, ends[k] - pos[k], alias=True))
    instrument = ("<Instrument><Name>%s</Name><GlobalProperties><Volume>1.0</Volume><Transpose>0</Transpose>"
                  "<BeatsPerMin>%s</BeatsPerMin></GlobalProperties><SampleGenerator><Samples>%s</Samples>"
                  "</SampleGenerator><ActiveGeneratorTab>Samples</ActiveGeneratorTab></Instrument>"
                  % (escape(name), fmt(A["bpm"]), "".join(samples)))
    # the patterns: one a clip
    clips = used_order(A)
    pidx = {c[0]: k for k, c in enumerate(clips)}
    pats = []
    for c in clips:
        cn, a, b, kind = c
        lines = []
        for bar in sbars:                 # every slice that starts in the clip, on its line
            if not (a <= bar < b + 1): continue
            at = (bar - a) * BL
            if bar == 0:                  # the lead-in: on the line (and delay, 256ths of a line) where the source starts in bar 0
                at = max(0.0, -bar_start(A, 0) / bar_len(A)) * BL
            n, d = int(at + 1e-9), int(round((at - int(at + 1e-9)) * 256))
            if d >= 256: n, d = n + 1, 0
            if bar == 0: n = min(n, BL - 1)
            line, delay = n, ("<Delay>%02X</Delay>" % d if d else "")
            lines.append("<Line index=\"%d\"><NoteColumns><NoteColumn><Note>%s</Note><Instrument>00</Instrument>%s"
                         "</NoteColumn></NoteColumns></Line>" % (line, note_name(note_of[bar]), delay))
        pats.append("<Pattern><Name>%s</Name><NumberOfLines>%d</NumberOfLines><Tracks>"
                    "<PatternTrack type=\"PatternTrack\"><Lines>%s</Lines></PatternTrack>"
                    "<PatternMasterTrack type=\"PatternMasterTrack\"><Lines/></PatternMasterTrack>"
                    "</Tracks></Pattern>" % (escape(label(c)), int(round((b - a + 1) * BL)), "".join(lines)))
    # the sequence: the arrangement, a section an entry; then the spare clips
    seq = []
    by = {c[0]: c for c in clips}
    F, fb = arrange.flat(A)
    for q, (c, r, pat, first) in enumerate(F):
        for k in range(r):
            seq.append((pidx[c], k == 0, entry_label(by[c], r, pat, first, q == fb and q > 0)))
    spare = [c for c in clips if c[0] not in {x[0] for x in F}]
    for k, c in enumerate(spare):
        seq.append((pidx[c[0]], k == 0, CLIPS_SECTION))
    entries = "".join("<SequenceEntry><Pattern>%d</Pattern><IsSectionStart>%s</IsSectionStart>"
                      "<SectionName>%s</SectionName></SequenceEntry>" % (p, "true" if s else "false", escape(n))
                      for p, s, n in seq)
    track = ("<SequencerTrack type=\"SequencerTrack\"><Name>%s</Name><Color>0,200,220</Color><State>Active</State>"
             "<NumberOfVisibleNoteColumns>1</NumberOfVisibleNoteColumns><NumberOfVisibleEffectColumns>1</NumberOfVisibleEffectColumns>"
             "<VolumeColumnIsVisible>true</VolumeColumnIsVisible><PanningColumnIsVisible>false</PanningColumnIsVisible>"
             "<DelayColumnIsVisible>true</DelayColumnIsVisible><TrackRouting>0</TrackRouting><Visible>true</Visible>%s"
             "</SequencerTrack>" % (escape(name), xml_track_devices(False)))
    master = ("<SequencerMasterTrack type=\"SequencerMasterTrack\"><Name>Mst</Name><State>Active</State>"
              "<NumberOfVisibleNoteColumns>0</NumberOfVisibleNoteColumns><NumberOfVisibleEffectColumns>1</NumberOfVisibleEffectColumns>"
              "<TrackRouting>0</TrackRouting><Visible>true</Visible>%s</SequencerMasterTrack>" % xml_track_devices(True, A["bpm"], lpb))
    comments = ["NEON-CASTER - %s, from music/%s.arr (music/daw.py)." % (name, name),
                "Each pattern is a clip; the sequence (up to the CLIPS section) is the arrangement, and loops.",
                "A note is a bar of the source, or a clip's piece of one (the instrument's slices). Edit, save, then:",
                "  daw.py --from-xrns %s.xrns" % name]
    return ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<RenoiseSong doc_version=\"63\">"
            "<GlobalSongData><BeatsPerMin>%s</BeatsPerMin><LinesPerBeat>%d</LinesPerBeat><TicksPerLine>12</TicksPerLine>"
            "<SignatureNumerator>4</SignatureNumerator><SignatureDenominator>4</SignatureDenominator>"
            "<MetronomeBeatsPerBar>4</MetronomeBeatsPerBar><SongName>%s</SongName><Artist>NEON-CASTER</Artist>"
            "<SongComments>%s</SongComments><ShowSongCommentsAfterLoading>false</ShowSongCommentsAfterLoading>"
            "<PlaybackEngineVersion>4</PlaybackEngineVersion></GlobalSongData>"
            "<Instruments>%s</Instruments><SelectedInstrumentIndex>0</SelectedInstrumentIndex>"
            "<Tracks>%s%s</Tracks><SelectedTrackIndex>0</SelectedTrackIndex>"
            "<PatternPool><Patterns>%s</Patterns></PatternPool>"
            "<PatternSequence><SequenceEntries>%s</SequenceEntries><PatternNameWidth>150</PatternNameWidth><KeepSequenceSorted>false</KeepSequenceSorted>"
            "</PatternSequence></RenoiseSong>\n"
            % (fmt(A["bpm"]), lpb, escape(name), "".join("<SongComment>%s</SongComment>" % escape(c) for c in comments),
               instrument, track, master, "".join(pats), entries))


def out_name(name):
    """A song's file name: NAME, or NAME-ALT for another arrangement of the take (NAME/ALT)."""
    return name.replace("/", "-")


def export_xrns(name, folder=None):
    import soundfile as sf
    A = arrange.read_arr(name)
    tk = arrange.take(name)
    src = source_flac(tk)
    info = sf.info(src)
    folder = folder or os.path.join(OUT, "renoise")
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, out_name(name) + ".xrns")
    xml = song_xml(tk, A, info.frames, info.samplerate, src)
    tmp = path + ".part"
    with zipfile.ZipFile(tmp, "w") as z:
        z.writestr("Song.xml", xml, compress_type=zipfile.ZIP_DEFLATED)
        z.write(src, "SampleData/Instrument00 (%s)/Sample00 (%s).flac" % (tk, tk), compress_type=zipfile.ZIP_STORED)
    os.replace(tmp, path)
    link_instruments(tk, folder)
    return A, path


def link_instruments(name, folder=None):
    """Beside the songs, instruments/NAME - TITLE/: a link to each of the track's Renoise
    instruments (soundmon's instruments.py writes them in its samples folder, 5 Instruments/
    Renoise) - so Renoise's browser finds them next to the song. Links, not copies; any old
    link there is replaced. Returns how many."""
    src = stems_folder(name)
    rn = os.path.join(src, "5 Instruments", "Renoise") if src else None
    if not rn or not os.path.isdir(rn): return 0
    folder = folder or os.path.join(OUT, "renoise")
    dst = os.path.join(folder, "instruments", os.path.basename(src))
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(dst):                       # (only our links: anything else there is left alone)
        if os.path.islink(os.path.join(dst, f)): os.remove(os.path.join(dst, f))
    n = 0
    for f in sorted(os.listdir(rn)):
        if f.endswith(".xrni"):
            os.symlink(os.path.relpath(os.path.join(rn, f), dst), os.path.join(dst, f)); n += 1
    return n


def import_xrns(path, name=None, out=None):
    import soundfile as sf
    name = name or name_from(path)
    A = arrange.read_arr(name)
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("Song.xml"))
        insts = root.findall("./Instruments/Instrument")
        # the sliced instrument: the first whose sample has slice markers
        inst, k_inst = None, -1
        for k, i in enumerate(insts):
            if i.find("./SampleGenerator/Samples/Sample/SliceMarkers/SliceMarker") is not None:
                inst, k_inst = i, k; break
        if inst is None:
            raise SystemExit("%s: no sliced instrument in the song" % path)
        smp = inst.findall("./SampleGenerator/Samples/Sample")
        pos = sorted(int(m.findtext("SamplePosition", "0")) for m in smp[0].findall("./SliceMarkers/SliceMarker"))
        sr = arrange.SR
        sdir = [f for f in z.namelist() if f.startswith("SampleData/") and re.search(r"Instrument0*%d \(" % k_inst, f)]
        if sdir:
            try: sr = sf.info(io.BytesIO(z.read(sorted(sdir)[0]))).samplerate
            except Exception: pass
        try: lpb = int(root.findtext("./GlobalSongData/LinesPerBeat") or LPB)
        except ValueError: lpb = LPB
    BL = 4 * lpb                                          # lines a bar
    # each slice's note -> its bar place (by where it starts in the source, to a 128th)
    def place_at(p):
        return round(((p / sr - A["offset"]) / bar_len(A) + 1) * STEPS) / STEPS
    note_bar, near = {}, {}
    try: base = int(smp[0].findtext("./Mapping/BaseNote"))
    except (TypeError, ValueError): base = FIRST_SLICE - 1
    for k, p in enumerate(pos):
        n = base + 1 + k
        if k + 1 < len(smp):
            try: n = int(smp[k + 1].findtext("./Mapping/NoteStart"))
            except (TypeError, ValueError): pass
        b = place_at(p)
        miss = abs(p / sr - bar_start(A, b))
        if b in near and near[b][1] <= miss: b = 0           # another slice is nearer that place (a lead-in)
        elif b in near: note_bar[near[b][0]] = 0
        if b < 1 - 1e-6 and k == 0 and A["offset"] >= 0.01: b = 0    # the first slice, before bar 1: the lead-in
        if b: near[b] = (n, miss)
        note_bar[n] = arrange.bar_num(b)
    places = sorted(set(note_bar.values()))
    def slice_end(b):                                     # where a slice's piece of the source ends
        if b == 0: return 1
        later = [x for x in places if x > b + 1e-6]
        return later[0] if later else A["bars"] + 1
    # each pattern: the pieces of the source it plays, in order - a note plays its slice to the
    # next note or the slice's end (any track but the master)
    lead_at = max(0.0, -bar_start(A, 0) / bar_len(A))     # where the lead-in's note sits in its bar
    pats = []
    for pt in root.findall("./PatternPool/Patterns/Pattern"):
        notes = []
        try: plen = int(pt.findtext("NumberOfLines") or 64) / BL
        except ValueError: plen = 64 / BL
        for tr in pt.findall("./Tracks/*"):
            if tr.tag != "PatternTrack": continue
            for ln in tr.findall("./Lines/Line"):
                li = int(ln.get("index", "0"))
                for col, nc in enumerate(ln.findall("./NoteColumns/NoteColumn")):
                    n = note_number(nc.findtext("Note"))
                    ins = nc.findtext("Instrument")
                    if n is None or n not in note_bar: continue
                    if ins not in (None, "", "..") and int(ins, 16) != k_inst: continue
                    try: dl = int(nc.findtext("Delay") or "0", 16)
                    except ValueError: dl = 0
                    at = (li + dl / 256.0) / BL               # where in the pattern, in bars
                    b = note_bar[n]
                    if b == 0: at = max(0.0, at - lead_at)    # (the lead-in's note sits where the source starts: its bar began before)
                    notes.append((round(at * STEPS) / STEPS, col, b))
        notes.sort()
        pieces = []
        for q, (at, col, b) in enumerate(notes):
            nxt = notes[q + 1][0] if q + 1 < len(notes) else plen
            d = min(nxt - at, slice_end(b) - b)
            if d > 1e-6: pieces.append((b, b + d))
        hint = (pt.findtext("Name") or "").split()
        pats.append((hint[0] if hint else None, pieces))
    # the sequence, up to CLIPS
    namer, order, cache, loop_i = Namer(A), [], {}, None
    groups, G, g = [], Groups(), None
    for e in root.findall("./PatternSequence/SequenceEntries/SequenceEntry"):
        if e.findtext("IsSectionStart") == "true" and (e.findtext("SectionName") or "").strip().upper() == CLIPS_SECTION:
            break
        if e.findtext("IsSectionStart") == "true" and (e.findtext("SectionName") or "").strip().startswith(LOOP_MARK):
            loop_i = len(order)
        if e.findtext("IsSectionStart") == "true": g = G.at(e.findtext("SectionName"))
        p = int(e.findtext("Pattern", "0"))
        if p >= len(pats): continue
        if p not in cache:
            hint, pieces = pats[p]
            cache[p] = [namer.name(arrange.bar_num(a), arrange.bar_num(e - 1), hint) for a, e in runs_of_pieces(pieces)]
        order += cache[p]
        groups += [g] * len(cache[p])
    return finish(name, A, namer.clips, order, out, loop_i, groups)


# --- BITWIG (DAWproject) ----------------------------------------------------
class Ids:
    def __init__(self): self.n = 0
    def __call__(self):
        self.n += 1
        return "id%d" % (self.n - 1)


def dp_clip(A, clip, time, seconds, audio_path, ids, loop=False, external=False):
    """A clip of the source's bars a..b at time (beats), nested as Bitwig writes its own: the outer
    clip is the bars (looping round them in its own beats, 0 to their length, in the launcher), the
    inner one the audio warped at the .arr's tempo, played from bar a. The lead-in's bar (0) starts
    before the file does: its inner clip starts that much later, so the beat still lines up."""
    c, a, b, kind = clip
    bpm = A["bpm"]
    start = bar_start(A, a) * bpm / 60.0               # the bar in the content's beats (the file's 0 is beat 0)
    dur = 4.0 * (b - a + 1)
    late = 0.0
    if start < 0: late, start = -start, 0.0            # the lead-in: silence till the file starts
    end_beats = seconds * bpm / 60.0
    lp = ' loopStart="0.0" loopEnd="%s"' % fmt(dur) if loop else ""
    return ('<Clip time="%s" duration="%s" contentTimeUnit="beats" playStart="0.0"%s fadeTimeUnit="beats" '
            'fadeInTime="0.0" fadeOutTime="0.0" name="%s" color="%s"><Clips id="%s">'
            '<Clip time="%s" duration="%s" contentTimeUnit="beats" playStart="%s" fadeTimeUnit="beats" '
            'fadeInTime="0.0" fadeOutTime="0.0">'
            '<Warps contentTimeUnit="seconds" timeUnit="beats" id="%s">'
            '<Audio algorithm="stretch" channels="2" duration="%s" sampleRate="%d" id="%s"><File path="%s"%s/></Audio>'
            '<Warp time="0.0" contentTime="0.0"/><Warp time="%s" contentTime="%s"/></Warps></Clip></Clips></Clip>'
            % (fmt(time), fmt(dur), lp, escape(label(clip)), clip_colour(A, clip), ids(),
               fmt(late), fmt(dur - late), fmt(start), ids(), fmt(seconds), arrange.SR, ids(),
               escape(audio_path), ' external="true"' if external else "", fmt(end_beats), fmt(seconds)))


# The stems (soundmon's stems.py, ~/Music/NEON-CASTER/samples/NAME - TITLE/1 Stems): each part of
# the take, as long as it and lined up with it to the sample - so every stem gets the take's clips.
# In groups, as they add up: the four-part split plays (it sums to the take, which is muted, kept
# to compare); the finer splits of the same sound are muted, to bring in in its place.
STEM_GROUPS = [
    ("STEMS", ["drums", "bass", "synths + fx", "vocals"], False),
    ("DRUMS SPLIT", ["kick", "snare", "toms", "hats", "ride", "crash"], True),
    ("SYNTHS BY RANGE", ["synth low", "synth mid", "synth high"], True),
    ("SYNTHS BY KIND", ["synth held", "synth hits"], True),
    ("SYNTHS DRY + REVERB", ["synth dry", "reverb"], True),
]
STEM_COLOURS = {"STEMS": "#ff5ac8", "DRUMS SPLIT": "#ffdc5a", "SYNTHS BY RANGE": "#5ae6ff",
                "SYNTHS BY KIND": "#aa78ff", "SYNTHS DRY + REVERB": "#78ff8c"}
SAMPLES = os.path.expanduser("~/Music/NEON-CASTER/samples")


def stems_folder(name):
    """The stems of track name (the folder stems.py made: "NAME - TITLE"), or None"""
    if not os.path.isdir(SAMPLES): return None
    for d in sorted(os.listdir(SAMPLES)):
        if d.startswith(name + " - ") and os.path.isfile(os.path.join(SAMPLES, d, "stems.json")):
            return os.path.join(SAMPLES, d)
    return None


def stem_groups(name):
    """[(group, colour, muted, [(part, absolute path, seconds)])] - the parts there are"""
    import soundfile as sf
    folder = stems_folder(name)
    if not folder: return []
    groups = []
    for g, parts, muted in STEM_GROUPS:
        have = []
        for part in parts:
            f = os.path.join(folder, "1 Stems", "%s - stem - %s.wav" % (name, part))
            if os.path.isfile(f):
                info = sf.info(f)
                have.append((part, f, info.frames / info.samplerate))
        if have: groups.append((g, STEM_COLOURS[g], muted, have))
    return groups


def project_xml(name, A, seconds, audio_path, stems=()):
    ids = Ids()
    bpm = A["bpm"]
    by = {c[0]: c for c in A["clips"]}
    tempo, sig = ids(), ids()
    master, mch = ids(), ids()
    def channel(cid, role, dest="", muted=False):
        return ('<Channel audioChannels="2"%s role="%s" solo="false" id="%s">'
                '<Mute value="%s" id="%s" name="Mute"/>'
                '<Pan max="1.000000" min="0.000000" unit="normalized" value="0.500000" id="%s" name="Pan"/>'
                '<Volume max="2.000000" min="0.000000" unit="linear" value="1.000000" id="%s" name="Volume"/>'
                '</Channel>' % (' destination="%s"' % dest if dest else "", role, cid,
                                "true" if muted else "false", ids(), ids(), ids()))
    # the tracks: the take, then each group of stems - (track id, audio path, external, seconds)
    track, tch = ids(), ids()
    audio = [(track, audio_path, False, seconds)]
    structure = ['<Track contentType="audio" loaded="true" id="%s" name="%s" color="#00c8dc">%s</Track>'
                 % (track, escape(name), channel(tch, "regular", mch, muted=bool(stems)))]
    for g, colour, muted, parts in stems:
        gid, gch = ids(), ids()
        kids = []
        for part, path, secs in parts:
            tid, cid = ids(), ids()
            audio.append((tid, path, True, secs))
            kids.append('<Track contentType="audio" loaded="true" id="%s" name="%s" color="%s">%s</Track>'
                        % (tid, escape("%s %s" % (name, part)), colour, channel(cid, "regular", gch)))
        structure.append('<Track contentType="tracks" loaded="true" id="%s" name="%s" color="%s">%s%s</Track>'
                         % (gid, escape(g), colour, channel(gch, "submix", mch, muted=muted), "".join(kids)))
    structure.append('<Track contentType="audio notes" loaded="true" id="%s" name="Master">%s</Track>'
                     % (master, channel(mch, "master")))
    # the arrangement: a clip per play on every track, a marker per entry
    lanes = {tid: [] for tid, _, _, _ in audio}
    markers, t = [], 0.0
    F, fb = arrange.flat(A)
    for q, (c, r, pat, first) in enumerate(F):
        cl = by[c]
        mk_name = entry_label(cl, r, pat, first, q == fb and q > 0)
        markers.append('<Marker time="%s" name="%s"/>' % (fmt(t), escape(mk_name)))
        for k in range(r):
            for tid, path, ext, secs in audio:
                lanes[tid].append(dp_clip(A, cl, t, secs, path, ids, external=ext))
            t += 4.0 * (cl[2] - cl[1] + 1)
    mk = ids()
    arrangement = ('<Arrangement id="%s"><Lanes timeUnit="beats" id="%s">%s</Lanes>'
                   '<Markers id="%s">%s</Markers></Arrangement>'
                   % (ids(), ids(), "".join('<Clips track="%s" id="%s">%s</Clips>' % (tid, ids(), "".join(lanes[tid]))
                                            for tid, _, _, _ in audio), mk, "".join(markers)))
    # the launcher: a scene a clip, the clip in every track's slot, looping
    scenes = []
    for cl in used_order(A):
        slots = "".join('<ClipSlot track="%s" hasStop="true" id="%s">%s</ClipSlot>'
                        % (tid, ids(), dp_clip(A, cl, 0.0, secs, path, ids, loop=True, external=ext))
                        for tid, path, ext, secs in audio)
        scenes.append('<Scene id="%s" name="%s"><Lanes timeUnit="beats" id="%s">%s</Lanes></Scene>'
                      % (ids(), escape(label(cl)), ids(), slots))
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Project version="1.0">'
            '<Application name="NEON-CASTER daw.py" version="1.0"/>'
            '<Transport><Tempo max="666.000000" min="20.000000" unit="bpm" value="%s" id="%s" name="Tempo"/>'
            '<TimeSignature denominator="4" numerator="4" id="%s"/></Transport>'
            '<Structure>%s</Structure>%s<Scenes>%s</Scenes></Project>\n'
            % ("%.6f" % bpm, tempo, sig, "".join(structure), arrangement, "".join(scenes)))


def metadata_xml(name):
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<MetaData><Title>%s</Title>'
            '<Artist>NEON-CASTER</Artist><Comment>From music/%s.arr (music/daw.py). The arrangement is the .arr; '
            'each scene is a clip. Edit, export as DAWproject, then: daw.py --from-dawproject %s.dawproject</Comment>'
            '</MetaData>\n' % (escape(name), escape(name), escape(name)))


def export_dawproject(name, folder=None):
    import soundfile as sf
    A = arrange.read_arr(name)
    tk = arrange.take(name)
    src = source_flac(tk)
    info = sf.info(src)
    folder = folder or os.path.join(OUT, "bitwig")
    os.makedirs(folder, exist_ok=True)
    path = os.path.join(folder, out_name(name) + ".dawproject")
    audio = "audio/%s.flac" % tk
    tmp = path + ".part"
    with zipfile.ZipFile(tmp, "w") as z:
        z.writestr("project.xml", project_xml(tk, A, info.frames / info.samplerate, audio, stem_groups(tk)),
                   compress_type=zipfile.ZIP_DEFLATED)
        z.writestr("metadata.xml", metadata_xml(tk), compress_type=zipfile.ZIP_DEFLATED)
        z.write(src, audio, compress_type=zipfile.ZIP_STORED)
    os.replace(tmp, path)
    return A, path


def _f(e, k, d=None):
    v = e.get(k)
    return float(v) if v not in (None, "") else d


def to_unit(x, frm, to, bpm):
    if frm == to or frm is None or to is None: return x
    return x * bpm / 60.0 if to == "beats" else x * 60.0 / bpm


TIMELINES = ("Warps", "Audio", "Clips", "Lanes", "Notes", "Timeline", "Video", "Points", "ClipSlot", "Markers")


def content_seconds(el, pos, unit, bpm, refs):
    """Where position pos (in unit) on a clip's content timeline el falls in its audio file, in
    seconds - through warps and clips inside clips. None if there's no audio."""
    tag = el.tag
    own = el.get("timeUnit") or unit
    pos = to_unit(pos, unit, own, bpm)
    if tag == "Audio":
        return to_unit(pos, own, "seconds", bpm)
    if tag == "Warps":
        cu = el.get("contentTimeUnit") or "seconds"
        W = sorted((_f(w, "time"), _f(w, "contentTime")) for w in el.findall("Warp"))
        if len(W) >= 2:
            k = 0
            while k < len(W) - 2 and pos > W[k + 1][0]: k += 1
            (t0, c0), (t1, c1) = W[k], W[k + 1]
            ct = c0 + (pos - t0) * (c1 - c0) / (t1 - t0) if t1 != t0 else c0
        elif W:
            ct = W[0][1] + to_unit(pos - W[0][0], own, cu, bpm)
        else:
            ct = to_unit(pos, own, cu, bpm)
        inner = next((x for x in el if x.tag in TIMELINES), None)
        if inner is None: return None
        return content_seconds(inner, ct, cu, bpm, refs)
    if tag in ("Clips", "Lanes"):
        kids = el.findall("Clip") if tag == "Clips" else [x for x in el if x.tag in TIMELINES]
        if tag == "Lanes":
            for x in kids:
                s = content_seconds(x, pos, own, bpm, refs)
                if s is not None: return s
            return None
        best = None
        for c in kids:
            t, d = _f(c, "time", 0.0), _f(c, "duration")
            if t <= pos + 1e-6 and (d is None or pos < t + d - 1e-6): best = c; break
        best = best if best is not None else (kids[0] if kids else None)
        if best is None: return None
        return clip_start_seconds(best, pos - _f(best, "time", 0.0), own, bpm, refs)
    return None


def clip_content(c, refs):
    inner = next((x for x in c if x.tag in TIMELINES), None)
    if inner is None and c.get("reference"): inner = refs.get(c.get("reference"))
    return inner


def clip_start_seconds(c, into, unit, bpm, refs):
    """Where a clip plays from in its audio, `into` (in unit) after the clip's start."""
    cu = c.get("contentTimeUnit") or unit
    inner = clip_content(c, refs)
    if inner is None: return None
    pos = _f(c, "playStart", 0.0) + to_unit(into, unit, cu, bpm)
    return content_seconds(inner, pos, cu, bpm, refs)


def import_dawproject(path, name=None, out=None):
    name = name or name_from(path)
    A = arrange.read_arr(name)
    track_name = arrange.take(name)              # (the take's track is named after the track, NAME/ALT's too)
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("project.xml"))
    refs = {e.get("id"): e for e in root.iter() if e.get("id")}
    tempo = root.find("./Transport/Tempo")
    bpm = float(tempo.get("value")) if tempo is not None else A["bpm"]
    arr = root.find("./Arrangement")
    if arr is None: raise SystemExit("%s: no arrangement" % path)
    # every track's clips on the arrangement: Clips with a track, under Lanes (whose timeUnit they take)
    found = {}
    def walk(el, unit):
        unit = el.get("timeUnit") or unit
        if el.tag == "Clips":
            found.setdefault(el.get("track") or "", []).append((el, unit))
            return
        for x in el:
            if x.tag in ("Lanes", "Clips"):
                if x.tag == "Lanes" and x.get("track") and not x.get("timeUnit"):
                    walk_track(x, unit, x.get("track"))
                else:
                    walk(x, unit)
    def walk_track(el, unit, trk):
        for x in el:
            if x.tag == "Clips": found.setdefault(trk, []).append((x, x.get("timeUnit") or el.get("timeUnit") or unit))
            elif x.tag == "Lanes": walk_track(x, x.get("timeUnit") or unit, trk)
    for x in arr:
        if x.tag == "Lanes": walk(x, x.get("timeUnit") or "beats")
    plays = []      # (time in beats, duration in beats, source seconds, loop beats or None, name hint)
    def take_first(kv):          # the take's track (named as the song; the stems are "NAME part"), else the most clips
        named = (refs.get(kv[0]) is not None and (refs[kv[0]].get("name") or "") == track_name)
        return (not named, -sum(len(c.findall("Clip")) for c, u in kv[1]))
    for trk, lst in sorted(found.items(), key=take_first):
        for clips_el, unit in lst:
            for c in clips_el.findall("Clip"):
                if c.get("enable") == "false": continue
                s = clip_start_seconds(c, 0.0, unit, bpm, refs)
                if s is None: continue
                t = to_unit(_f(c, "time", 0.0), unit, "beats", bpm)
                cu = c.get("contentTimeUnit") or unit
                d = _f(c, "duration")
                if d is None:
                    d = to_unit((_f(c, "playStop", 0.0) - _f(c, "playStart", 0.0)), cu, unit, bpm)
                d = to_unit(d, unit, "beats", bpm)
                loop = None
                ls, le = _f(c, "loopStart"), _f(c, "loopEnd")
                if ls is not None and le is not None and le > ls:
                    loop = to_unit(le - ls, cu, "beats", bpm)
                hint = (c.get("name") or "").split()
                plays.append((t, d, s, loop, hint[0] if hint else None))
        if plays: break          # the first track (most clips) with audio
    plays.sort()
    loop_t = None                # a marker named "| ...": the loop starts there (what's before it is an intro)
    for mk in arr.iter("Marker"):
        if (mk.get("name") or "").strip().startswith(LOOP_MARK):
            mu = None
            for el in arr.iter("Markers"): mu = el.get("timeUnit") or mu
            loop_t = to_unit(_f(mk, "time", 0.0), mu or "beats", "beats", bpm)
    namer, order, loop_i, groups = Namer(A), [], None, []
    marks = []                   # every marker (beats, name): the pattern's play a clip is in, by the one it's under
    for mk in arr.iter("Marker"):
        mu = None
        for el in arr.iter("Markers"): mu = el.get("timeUnit") or mu
        marks.append((to_unit(_f(mk, "time", 0.0), mu or "beats", "beats", bpm), mk.get("name") or ""))
    marks.sort()
    G, mg = Groups(), []
    for mt, mn in marks: mg.append((mt, G.at(mn)))
    def group_at(t):
        g = None
        for mt, gg in mg:
            if mt <= t + 1e-3: g = gg
            else: break
        return g
    bl = bar_len(A)
    lead = A["offset"] >= 0.01
    qs = lambda x: round(x * STEPS) / STEPS             # (to a 128th of a bar: the game's arranger's finest)
    for t, d, s, loop, hint in plays:
        first = qs((s - A["offset"]) / bl + 1)
        if lead and s < A["offset"] - 0.02:            # it starts before bar 1: the lead-in - bar 0 counted whole
            first = 0
            d += (s - bar_start(A, 0)) / bl * 4.0
        n = max(1 / STEPS, qs(d / 4.0))
        reps = 1
        if loop and loop < d - 1e-3:
            ln = max(1 / STEPS, qs(loop / 4.0))
            reps, n = max(1, int(round(d / loop))), ln
        first = max(0 if lead else 1, first)
        last = min(A["bars"], first + n - 1)
        if last + 1 <= first: continue
        first, last = arrange.bar_num(first), arrange.bar_num(last)
        if loop_t is not None and loop_i is None and t >= loop_t - 1e-3: loop_i = len(order)
        order += [namer.name(first, last, hint)] * reps
        groups += [group_at(t)] * reps
    return finish(name, A, namer.clips, order, out, loop_i, groups)


# --- THE COMMAND LINE -------------------------------------------------------
def main(argv):
    out = folder = None
    args = []
    k = 0
    while k < len(argv):
        if argv[k] == "--out": out = argv[k + 1]; k += 2; continue
        if argv[k] == "--dir": folder = argv[k + 1]; k += 2; continue
        args.append(argv[k]); k += 1
    rest = [a for a in args if not a.startswith("--")]
    if "--xrns" in args or "--dawproject" in args:
        names = rest or arrange.tracks()
        for n in names:
            if "--xrns" in args:
                A, p = export_xrns(n, folder)
                print(summary(n, A, p), flush=True)
            if "--dawproject" in args:
                A, p = export_dawproject(n, folder)
                print(summary(n, A, p), flush=True)
    elif "--from-xrns" in args or "--from-dawproject" in args:
        if not rest: raise SystemExit("which file?")
        f = rest[0]
        n = rest[1] if len(rest) > 1 else None
        B = (import_xrns if "--from-xrns" in args else import_dawproject)(f, n, out)
        print(summary(n or name_from(f), B, out or arrange.arr_path(n or name_from(f))))
    else:
        print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
