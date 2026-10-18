# 規約チェック (AI音楽の扱い)

最終確認日: 2026-10-18
注意: 今回 WebFetch が全ドメインで名前解決エラー(ENOTFOUND)となり、公式ページ本文を直接読めていない。以下は検索結果の要約(検索エンジン経由)に基づく。公式本文での再確認は「未確認」。

## DistroKid
- 公式ヘルプ記事が存在する(本文は未取得):
  - Can I Upload Music Made With AI Tools to DistroKid? https://support.distrokid.com/hc/en-us/articles/41182362733715-Can-I-Upload-Music-Made-With-AI-Tools-to-DistroKid
  - How to Fill Out AI Credits https://support.distrokid.com/hc/en-us/articles/50784709021971-How-to-Fill-Out-AI-Credits
  - What Are AI Credits? https://support.distrokid.com/hc/en-us/articles/50784235803411-What-Are-AI-Credits
- 検索要約による内容(公式ページの要約。原文引用は未確認):
  - アップロード時に「AIが使われたか」を尋ねられる。Yesの場合、歌詞/作曲/音声の全部/音声の一部を選択。「音声の全部」を選ぶとアーティストが人間かAIペルソナかも聞かれる。
  - 回答は配信先のクレジット表示に使われる。リリース後も distrokid.com/credits やアルバムページの「Credits」から編集可。
  - ピッチ補正、AI補助のミックス/マスタリングなど「単なるツール」利用ならAIクレジット不要。
  - アップロードする権利を100%保有していること。他者の声・肖像の無許可模倣は不可。
  - Spotifyの認証バッジ(Verified by Spotify)は、主にAI生成/AIペルソナのプロフィールは開始時点で対象外(https://support.distrokid.com/hc/en-us/articles/51650814153363-What-is-the-New-Verified-by-Spotify-Badge )。
- 第三者ブログ(二次情報): 5月14日にAI開示が導入されたとの記述あり。公式での日付は未確認。 https://jackrighteous.com/ja/blogs/ai-music-distribution-guide/ai-music-distribution-rules-distrokid-spotify-apple-deezer
- Sunoの商用利用権(有料プランか、生成時のプラン等)はDistroKid側ではなくSuno規約側の確認が必要。今回は未確認。

## Spotify
- 2025-09-25 のAIポリシー更新(TechCrunch報道): https://techcrunch.com/2025/09/25/spotify-updates-ai-policy-to-label-tracks-cut-down-on-spam
  - 無許可のボイスクローン/なりすまし禁止。
  - スパムフィルタ(大量アップロード、重複、メタデータのSEO操作、極端に短い曲)。直近12か月で7,500万曲超を削除したと報道。
  - DDEX規格によるAI利用のクレジット開示(ボーカル/楽器/ポスプロ)。透明性を理由にした順位下げはしないとされる。
- 公式ニュースルーム(newsroom.spotify.com)は取得不可。公式本文は未確認。
- DDEX展開状況は二次情報(Dynamoi等)で「2026年3月時点で配信事業者と連携中」とのみ。詳細は未確認。 https://dynamoi.com/learn/ai-music-distribution/spotify-ai-music-policy

## Apple Music / YouTube / TikTok / Deezer
- 未確認(二次情報のまとめ記事 https://jackrighteous.com/ja/blogs/ai-music-distribution-guide/ai-music-distribution-rules-distrokid-spotify-apple-deezer が存在するが、本文未読)。

## 運用への示唆
- アップロード時はAI開示を必ず正直に入力する(Suno全生成なら「音声の全部」に該当すると思われるが、選択肢の正確な文言は未確認)。
- 週1〜2曲までの厳選、重複・極端に短い曲を避ける、メタデータを盛らない。
- 人間タスク: アップロード前にDistroKid公式ヘルプとSuno規約を人が最終確認(tasks/human-todo.md 参照)。
