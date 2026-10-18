# 秋風にさよなら / Suno プロンプト(案B)

出典: plans/2026-10-18.md 案B(優先度: 中)。案Aとの対比用の検証枠。根拠は薄い。

## Style プロンプト(英語・ジャンル用語のみ)
```
J-pop rock, youthful pop rock, mid-tempo, nostalgic and bittersweet, clean electric guitar arpeggios, warm acoustic guitar, steady drums, melodic bass, light piano, sing-along chorus, expressive female vocal, anthemic final chorus, polished modern production
```

## テンポ・キー
- BPM: 112〜120(Style欄に "115 bpm" を追記可)
- キー: 長調ベース、サビで切なさ(例: A major。出力次第)
- 目標曲尺: 3〜4分

## 構成
Intro(クリーンギター) → Verse1 → Pre-Chorus → Chorus → Verse2 → Pre-Chorus → Chorus → Bridge(静かに入り盛り上げ) → Last Chorus → Outro(ピアノとギターで余韻)

## Exclude(Negative prompt)
```
lo-fi, chillhop, EDM drop, rap, screaming, heavy metal, aggressive, ballad-only piano, instrumental only, mumbling vocals
```

## 生成バリエーション数の目安
- 初回: 3回生成(1回2曲=6曲)を試聴。
- 不満点が歌詞の長さ/発音なら歌詞を微修正して最大2回まで追加。
- 微差の量産はしない。最終候補は最大1曲。

## 試聴選定チェックリスト(人が試聴して選ぶ)
- [ ] 曲尺が2.5分以上ある
- [ ] 歌詞の脱落・誤読・意味不明な反復がない
- [ ] 日本語の発音が自然(サビ・「ロッカー」「放課後」等の語)
- [ ] ボーカルが不自然でなく、声質が途中で変わらない
- [ ] 中テンポで歌いやすく、サビが覚えやすい
- [ ] 季節感(秋・夕方の切なさ)が伝わる
- [ ] 案Aと明確に違う曲調になっている(重複感がない)
- [ ] 既存曲のメロディに酷似していない
- [ ] 終わり方が自然
- [ ] 総合で「週の候補にして良い」か「見送り」か記録(案Aとの比較も)
- メモ欄: 採用ID / 理由 / 見送り理由
