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

## 追記 2026-10-19 (新規分のみ。WebFetchは引き続き不可、すべて二次情報・未確認)
- DistroKid: 10月時点の新たな方針変更の報道は検索で見つからず(未確認)。AI開示は新規アップロードのみ対象で遡及適用なし、自己申告制(検出ツールに依存しない)との要約あり。 https://www.musicinafrica.net/fr/node/391306
- 受理条件の要約: 権利を保有していれば受理、なりすまし・侵害・大量生成スパムは禁止(第三者ブログ要約、DistroKid公式文言は未確認)。 https://www.soundverse.ai/blog/article/does-distrokid-allow-ai-generated-music-1155
- 重要・要確認 Suno規約: 2026-09-03発効の規約で、商用利用は「有料プラン加入中にダウンロードした曲」に限られ、月間ダウンロード上限(Pro 20曲/Premier 60曲)があるとの記述。無料プラン生成曲は商用不可(権利はSuno側)、有料化後の遡及も不可で再生成が必要との記述。出典は二次情報であり、Suno公式は未確認。 https://aiagent-navi.com/?p=22067 , https://dynamoi.com/ja/learn/ai-music-distribution/how-to-distribute-suno-music
  - 運用上の示唆: Suno生成は有料プラン加入中に行いダウンロードする。月間上限を踏まえ、下書き生成のダウンロードを絞る。アップロード前に人がSuno公式規約を確認すること。
- 注意喚起(ベンダー記事、未検証): 「配信前に音声を加工すべき」とする業者ガイドがあるが、検出回避目的の加工は規約違反リスクがあるため推奨しない。 https://undetectr.com/blog/suno-to-spotify

## 追記 2026-10-30 (新規分のみ。WebFetchは musicbusinessworldwide.com で名前解決エラー。すべてWebSearch要約に基づく二次情報、公式本文は未確認)
- Spotify(2026-10-20発表): 今年「AIスロップ/スパム」とみなした5,000万曲超を推薦から除外(カタログ削除とは別。別途、重大/反復違反で7,500万曲超を削除との説明)。判定は単一シグナルでなく、エンゲージメント、アップロードパターン、メタデータ、第三者AI検出の組み合わせ。AI生成の可能性が高い曲は年間1,000再生のしきい値を下回る確率が10倍(会社申告)。AI生成とされるアーティストIDは既定で推薦から除外・ラベル付けされているとの報道。AI Credits(2026年4月開始)は1日数万件提出。5,000万曲のうちAI生成の数は不明。 https://thenextweb.com/news/spotify-50-million-ai-slop-tracks-recommendations , https://au.variety.com/2026/music/news/spotify-removes-50-million-ai-slop-tracks-recommendations-41607/ , https://www.1news.co.nz/2026/10/21/spotify-removes-more-than-50-million-ai-slop-tracks/
  - 運用上の示唆: AI開示(DistroKidのAIクレジット)を正直に入力し、大量・類似曲・メタデータ盛りを避ける。推薦除外の対象にならない運用(厳選リリース)が重要。
- DistroKid/UMG訴訟(新規・重要): 2026-09-15、UMGがDistroKidを米デラウェア連邦地裁に提訴。UMG録音物を模倣した1,000作品の著作権侵害等を主張。訴状は「明示的に開示されたAI音楽の配信自体が対象ではない」と記載との報道。DistroKidは争う姿勢で、請求を受けたトラックを削除したと確認、アーティストへ事前警告がなかったとの苦情あり。 https://www.digitalmusicnews.com/2026/09/15/universal-music-distrokid-lawsuit/ , https://www.musicbusinessworldwide.com/universal-music-group-sues-distrokid/ , https://www.musicbusinessworldwide.com/distrokid-confirms-it-has-removed-tracks-in-response-to-umg-claims/
  - 運用上の示唆: 既存曲に似た楽曲は削除・アカウント影響のリスク。実在曲・アーティストの模倣禁止(CLAUDE.md)を厳守。アップロード前の類似チェックを人が実施。
- DistroKid: 10月の公式なAI方針変更は検索で見つからず(未確認)。「遡及適用・再スキャン」とする業者記事(undetectr)があるが、他に裏付けなく未確認。 https://undetectr.com/blog/distrokid-ai-policy-2026
- Suno: 2026-08-10発表・09-03施行の上限(無料は通算7回、Pro月20、Premier月60)を複数報道で再確認。既存ライブラリにも適用との報道あり、未使用分の繰り越しなしとの記述あり。10月の追加変更は見つからず。Suno公式は未確認。 https://www.musicbusinessworldwide.com/suno-limits-pro-subscribers-to-20-song-downloads-per-month , https://forklog.com/en/news/suno-imposes-music-download-limits-amid-legal-and-content-concerns
