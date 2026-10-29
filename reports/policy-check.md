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

## 追記 2026-10-29 (WebFetchは support.distrokid.com / suno.com / help.suno.com すべて ENOTFOUND。公式本文は未確認、検索要約ベース)
- Suno 規約・ダウンロード方針: Suno公式ブログ「An update to our downloads policy and Terms of Service」とヘルプ「Upcoming Changes FAQ」の存在を検索で確認(本文未取得)。 https://suno.com/blog/suno-updates-tos , https://help.suno.com/en/articles/13614785
  - 発表2026-08-10、発効2026-09-03(二次報道の要約)。10-19記載の内容を複数の二次情報で再確認: Free は試用7ダウンロードで個人利用のみ、Pro 月20曲、Premier 月60曲、上限超過分は追加購入可。有料プランでダウンロードした曲は商用利用可。 https://www.aimusicpreneur.com/ai-tools-news/suno-download-caps-free-pro-premier-september-2026/ , https://diyai.io/ai-tools/audio-generation/suno-pricing/ , https://www.musicbusinessworldwide.com/suno-limits-subscribers-downloads-per-month/
  - 新情報(二次情報): Remix(ユーザーのリミックス)は階層に関わらず非商用との報道。仲裁条項が更新されたとの記述。
  - 新情報(二次情報・未確認): Warner Music Groupとの合意に基づく新世代のライセンスモデルが登場予定で、発売日は未発表。既存モデルを2026年中に廃止との報道もあり。 https://roo.beehiiv.com/p/suno-new-models-september-2026 , https://www.musicinafrica.net/magazine/suno-adjusts-ai-music-ownership-terms-after-warner-music-partnership
  - 注意: 「権利はSuno側が保持し、ユーザーに永続的商用ライセンスを付与」と読める解説がある一方、Suno自身の文言(ユーザーのもの)と食い違う。未確認。人が公式で確認すること。
  - 運用上の示唆: ダウンロードは有料プラン加入中に限り、月間上限を意識して厳選。モデル移行時に既存曲の扱いが変わる可能性があるため、公式告知を継続監視。
- Spotify: 10月の新たな公式発表は見つからず(未確認)。2025-09の枠組み(開示・なりすまし禁止・スパム対策)が基本として引用され続けている。AIペルソナを編集/アルゴリズム推薦に含めない旨の報道があるが日付・出典の信頼性が不明(未確認)。 https://relix.com/news/detail/spotify-targets-ai-slop-and-embraces-ai-music-in-new-policy
- DistroKid: 2026年10月の規約変更は検索で見つからず(未確認)。受理条件(権利保有、なりすまし・大量生成禁止、AIクレジット申告)は従来どおりとの二次情報。 https://www.soundverse.ai/blog/article/does-distrokid-allow-ai-generated-music-1155
  - 未検証: 2026年7月にSuno曲が一部ストアで拒否されたとの個人体験談(理由不明)。 https://jackrighteous.com/ja/blogs/ai-music-distribution-guide/why-distrokid-rejected-ai-music
- 対応: 公式本文を読むには上記ドメインのネットワーク許可が必要。許可されない場合は人が直接確認(tasks/human-todo.md に既出)。
