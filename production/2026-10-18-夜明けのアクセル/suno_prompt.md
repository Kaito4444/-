# 夜明けのアクセル / Suno プロンプト(案A)

出典: plans/2026-10-18.md 案A(優先度: 高)。検証枠の仮説であり、成果は未確認。

## Style プロンプト(英語・ジャンル用語のみ)
```
anime opening style, energetic J-rock, uplifting pop rock, fast tempo, driving drums, bright distorted electric guitars, melodic bass, catchy hook, soaring female vocal, powerful chorus, key change before final chorus, polished modern production
```
(1000文字以内・約230文字。実在アーティスト名/作品名は含めない)

## テンポ・キー
- BPM: 172前後(Style欄に数値を入れると効きやすい場合は "170 bpm" を追記)
- キー: 明るい長調(例: E major など。Sunoの出力次第)
- 目標曲尺: 2.5〜3.5分(短すぎる出力は不採用)

## 構成(歌詞タグと対応)
Intro(ギターリフ 4小節) → Verse1 → Pre-Chorus → Chorus → Verse2 → Pre-Chorus → Chorus → Bridge → Last Chorus(転調) → Outro

## Exclude(Negative prompt)
```
lo-fi, ambient, slow ballad, rap, spoken word, heavy metal growl, screaming, autotune-heavy, sad mood, instrumental only, mumbling vocals
```

## 生成バリエーション数の目安
- 初回: 3〜4回生成(1回2曲=6〜8曲)を試聴。
- 歌詞の崩れ・曲尺不足が多ければ、歌詞の1行を短く直して追加で最大2回まで。
- 微差バージョンの量産はしない(重複対策)。最終候補は1曲のみ。

## 試聴選定チェックリスト(人が試聴して選ぶ)
- [ ] 曲尺が2.5分以上ある(極端に短くない)
- [ ] 歌詞が指定どおり歌われ、誤読・脱落・意味不明な繰り返しがない
- [ ] 日本語の発音が不自然でない(特にサビ)
- [ ] ボーカルに機械的なノイズ・不自然なビブラート・声質の途中変化がない
- [ ] サビが1回で覚えられるくらいキャッチー
- [ ] 疾走感がありつつ、ドラム/ギター/ボーカルのバランスが良い
- [ ] 転調が自然で、終わり方が唐突でない(フェードや不自然な切断がない)
- [ ] 既存曲のメロディに酷似していない(違和感があれば不採用)
- [ ] 英語フレーズ("Take the wheel" 等)の発音が許容範囲
- [ ] 総合で「週の候補にして良い」か、「見送り」か判断を記録
- メモ欄: 採用ID / 理由 / 見送り理由
