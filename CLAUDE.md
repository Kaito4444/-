# DistroKid アニソン風プロジェクト

目的: アニソン風(J-POP寄りのアニメ主題歌調)楽曲をSunoで制作し、DistroKidで配信して収益化する。
(Lo-fiは別プロジェクトなのでここでは扱わない)

## 役割と出力先
- researcher → `research/YYYY-MM-DD.md`
- planner    → `plans/YYYY-MM-DD.md`
- producer   → `production/YYYY-MM-DD-曲名/` (suno_prompt.md, lyrics.md, cover.md)
- marketer   → `marketing/YYYY-MM-DD.md`
- analyst    → `reports/YYYY-MM-DD.md` と `reports/metrics.csv`(人が追記した数値を読む)

## 毎日の流れ (朝5時 JST)
researcher → planner → producer → marketer → analyst の順に実行し、日次サマリを `reports/` に書いて commit する。

## 絶対ルール
- 既存アーティスト・作品・キャラの名前、歌詞、メロディの模倣をしない(著作権・規約違反)。スタイル指定はジャンル用語のみ。
- AI生成の開示: DistroKid・各配信ストアの最新規約を確認し、`reports/policy-check.md` に根拠付きで残す。
- 制作は毎日行う(1日1〜3曲分のSuno指示書)が、DistroKidへのアップロードは厳選する。大量・低品質リリースはしない(スパム判定・収益停止リスク)。
- 厳選基準: 試聴で良いと感じた曲のみ。アップロード候補は週1〜2曲まで。毎日の `plans/` に「今日の制作分」と「アップロード推薦(あれば)」を分けて書く。
- 収益や再生数を推測で書かない。数値は `reports/metrics.csv` の実績のみ使う。
- 人間の作業(Sunoでの生成・試聴選定、DistroKidへのアップロード)は `tasks/human-todo.md` に追記して依頼する。
