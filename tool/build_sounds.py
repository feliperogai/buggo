"""Converte os efeitos escolhidos (Kenney, CC0) de .ogg para .mp3.

Os pacotes da Kenney só vêm em Ogg Vorbis, que o iOS não decodifica
(AVAudioPlayer não suporta Vorbis). Este script escolhe os arquivos usados
pelo app, converte para mono MP3, normaliza o volume por categoria e apaga
o resto.

Uso:  py tool/build_sounds.py
"""
import os
import sys

import lameenc
import numpy as np
import soundfile as sf

SOUNDS_DIR = "assets/sounds"
BITRATE = 96

# destino -> (arquivo de origem sem extensão, pico alvo 0..1)
#
# Os efeitos que tocam o tempo todo (acerto, erro, toque) ficam mais baixos
# que as celebrações, que são momentos pontuais.
MAPPING = {
    "correct.mp3": ("confirmation_001", 0.50),
    "wrong.mp3": ("error_006", 0.50),
    "life_lost.mp3": ("error_003", 0.60),
    "purchase.mp3": ("confirmation_002", 0.60),
    "coin.mp3": ("chip-lay-1", 0.55),
    "tap.mp3": ("click_001", 0.40),
    "lesson_complete.mp3": ("jingles_STEEL16", 0.85),
    "level_up.mp3": ("jingles_NES00", 0.80),
    "achievement.mp3": ("jingles_SAX07", 0.80),
    "streak.mp3": ("jingles_HIT00", 0.75),
}


def convert(src_path: str, dst_path: str, target_peak: float) -> None:
    data, rate = sf.read(src_path, always_2d=True, dtype="float64")

    # Mono: efeito de UI não ganha nada com estéreo e ocupa o dobro.
    mono = data.mean(axis=1)

    peak = np.abs(mono).max()
    if peak > 0:
        mono = mono * (target_peak / peak)

    # Fade-out de 5ms evita o "clique" no fim do arquivo.
    fade = min(int(rate * 0.005), len(mono))
    if fade > 0:
        mono[-fade:] *= np.linspace(1.0, 0.0, fade)

    pcm = np.clip(mono * 32767, -32768, 32767).astype("<i2")

    encoder = lameenc.Encoder()
    encoder.set_bit_rate(BITRATE)
    encoder.set_in_sample_rate(rate)
    encoder.set_channels(1)
    encoder.set_quality(2)  # 2 = alta qualidade
    mp3 = encoder.encode(pcm.tobytes())
    mp3 += encoder.flush()

    with open(dst_path, "wb") as fh:
        fh.write(mp3)

    dur = len(mono) / rate
    size_kb = len(mp3) / 1024
    print(f"  {os.path.basename(dst_path):22s} <- {os.path.basename(src_path):22s}"
          f" {dur:5.2f}s  {size_kb:5.1f} KB")


def main() -> int:
    missing = []
    print("Convertendo:")
    for dst, (src, peak) in MAPPING.items():
        src_path = os.path.join(SOUNDS_DIR, f"{src}.ogg")
        if not os.path.exists(src_path):
            missing.append(src)
            continue
        convert(src_path, os.path.join(SOUNDS_DIR, dst), peak)

    if missing:
        print(f"\nERRO: arquivos de origem não encontrados: {missing}")
        return 1

    # Limpa os .ogg que sobraram (os 222 do pacote original).
    removed = 0
    for name in os.listdir(SOUNDS_DIR):
        if name.endswith(".ogg"):
            os.remove(os.path.join(SOUNDS_DIR, name))
            removed += 1
    print(f"\n{removed} arquivos .ogg não utilizados removidos.")

    total = sum(
        os.path.getsize(os.path.join(SOUNDS_DIR, dst)) for dst in MAPPING
    )
    print(f"Total dos efeitos usados: {total / 1024:.1f} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
