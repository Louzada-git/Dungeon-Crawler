extends Node
# Short original procedural sounds generated locally; bounded positional voices.
var enabled: bool = true
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var cursor: int = 0

func _ready() -> void:
 for id in ["step","swing","hit","hurt","loot"]:
  streams[id] = load("res://assets/audio/"+id+".wav")
 for i in 10:
  var voice = AudioStreamPlayer3D.new()
  voice.max_distance = 20
  voice.unit_size = 5
  voice.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
  add_child(voice)
  voices.append(voice)

func play_at(id: String, pos: Vector3, volume: float = 1.0) -> void:
 if not enabled or voices.is_empty() or not streams.has(id):
  return
 var voice = voices[cursor]
 cursor = (cursor+1)%voices.size()
 voice.stream = streams[id]
 voice.global_position = pos+Vector3.UP*0.7
 voice.volume_db = linear_to_db(maxf(0.01,volume))-6
 voice.pitch_scale = randf_range(0.94,1.06)
 voice.play()
