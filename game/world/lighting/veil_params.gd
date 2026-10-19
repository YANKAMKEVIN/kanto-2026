class_name VeilParams
extends RefCounted
## Réglages du trou du voile d'obscurité à un instant donné ([DarknessProfile], [VeilMath]), en
## pixels du monde : halo net, fin du fondu, opacité hors du halo. Donnée pure.

## Rayon du halo net (opacité 0), pixels.
var clear_px: float = 0.0
## Fin du fondu (opacité [member outside] au-delà), pixels.
var fade_px: float = 0.0
## Opacité du voile hors du halo (< 1 : jamais de noir total).
var outside: float = 0.0


static func make(clear: float, fade: float, opacity: float) -> VeilParams:
	var params := VeilParams.new()
	params.clear_px = clear
	params.fade_px = fade
	params.outside = opacity
	return params


func is_equal_to(other: VeilParams) -> bool:
	return other != null and is_equal_approx(clear_px, other.clear_px) \
		and is_equal_approx(fade_px, other.fade_px) and is_equal_approx(outside, other.outside)
