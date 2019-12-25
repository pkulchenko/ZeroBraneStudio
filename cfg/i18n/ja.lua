--- @author Yu Tang
return {
  ["%s event failed: %s"] = "%s イベントの処理に失敗しました： %s", -- src\editor\package.lua
  ["%s%% formatted..."] = "フォーマット中（%s%%）...", -- src\editor\print.lua
  ["%s%% loaded..."] = "読込中（%s%%）...", -- src\editor\commands.lua
  ["&About"] = "ZeroBrane Studio について(&A)", -- src\editor\menu_help.lua
  ["&Add Watch"] = "ウォッチ式の追加(&A)", -- src\editor\debugger.lua
  ["&Break"] = "ブレーク(&B)", -- src\editor\menu_project.lua
  ["&Close Page"] = "このページを閉じる(&C)", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["&Community"] = "コミュニティ(&C)", -- src\editor\menu_help.lua
  ["&Compile"] = "コンパイル(&C)", -- src\editor\menu_project.lua
  ["&Copy Value"] = "値をコピー(&C)", -- src\editor\debugger.lua
  ["&Copy"] = "コピー(&C)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Default Layout"] = "既定のレイアウトを復元(&D)", -- src\editor\menu_view.lua
  ["&Delete Watch"] = "ウォッチ式の削除(&D)", -- src\editor\debugger.lua
  ["&Delete"] = "削除(&D)", -- src\editor\filetree.lua
  ["&Documentation"] = "ドキュメンテーション(&D)", -- src\editor\menu_help.lua
  ["&Edit Project Directory"] = "プロジェクトフォルダーのパスを編集して移動(&E)", -- src\editor\filetree.lua
  ["&Edit Value"] = "値を編集(&E)", -- src\editor\debugger.lua
  ["&Edit Watch"] = "ウォッチ式を編集(&E)", -- src\editor\debugger.lua
  ["&Edit"] = "編集(&E)", -- src\editor\menu_edit.lua
  ["&File"] = "ファイル(&F)", -- src\editor\menu_file.lua
  ["&Find"] = "検索(&F)", -- src\editor\menu_search.lua
  ["&Fold/Unfold All"] = "コード折りたたみを全切り替え(&F)", -- src\editor\menu_edit.lua
  ["&Frequently Asked Questions"] = "よくある質問(&F)", -- src\editor\menu_help.lua
  ["&Getting Started Guide"] = "使い方ガイド(&G)", -- src\editor\menu_help.lua
  ["&Help"] = "ヘルプ(&H)", -- src\editor\menu_help.lua
  ["&New Directory"] = "フォルダーを新規作成(&N)", -- src\editor\filetree.lua
  ["&New"] = "新規作成(&N)", -- src\editor\menu_file.lua
  ["&Open..."] = "開く(&O)...", -- src\editor\menu_file.lua
  ["&Output/Console Window"] = "出力/コンソールウィンドウ(&O)", -- src\editor\menu_view.lua
  ["&Paste"] = "貼り付け(&P)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Print..."] = "印刷(&P)...", -- src\editor\print.lua
  ["&Project Page"] = "プロジェクトページ(&P)", -- src\editor\menu_help.lua
  ["&Project"] = "プロジェクト(&P)", -- src\editor\menu_project.lua
  ["&Redo"] = "やり直し(&R)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&Rename"] = "名前の変更(&R)", -- src\editor\filetree.lua
  ["&Replace"] = "置換(&R)", -- src\editor\menu_search.lua
  ["&Run"] = "実行(&R)", -- src\editor\menu_project.lua
  ["&Save"] = "保存(&S)", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["&Search"] = "検索(&S)", -- src\editor\menu_search.lua
  ["&Select Command"] = "コマンドの選択(&S)", -- src\editor\gui.lua
  ["&Sort"] = "並べ替え(&S)", -- src\editor\menu_edit.lua
  ["&Stack Window"] = "スタックウィンドウ(&S)", -- src\editor\menu_view.lua
  ["&Start Debugger Server"] = "デバッガーサーバーを起動(&S)", -- src\editor\menu_project.lua
  ["&Status Bar"] = "ステータスバー(&S)", -- src\editor\menu_view.lua
  ["&Tool Bar"] = "ツールバー(&T)", -- src\editor\menu_view.lua
  ["&Tools"] = "ツール(&T)", -- src\editor\package.lua
  ["&Tutorials"] = "チュートリアル(&T)", -- src\editor\menu_help.lua
  ["&Undo"] = "取り消し(&U)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["&View"] = "表示(&V)", -- src\editor\menu_view.lua
  ["&Watch Window"] = "ウォッチウィンドウ(&W)", -- src\editor\menu_view.lua
  ["About %s"] = "%s について", -- src\editor\menu_help.lua
  ["Add To Scratchpad"] = "スクラッチパッドへ追加", -- src\editor\editor.lua
  ["Add Watch Expression"] = "ウォッチ式を追加", -- src\editor\editor.lua
  ["All files"] = "すべてのファイル", -- src\editor\commands.lua
  ["Allow external process to start debugging"] = "外部プロセスからデバッグできるようにします", -- src\editor\menu_project.lua
  ["Analyze the source code"] = "ソースコードを解析します", -- src\editor\inspect.lua
  ["Analyze"] = "解析", -- src\editor\inspect.lua
  ["Auto Complete Identifiers"] = "識別子の自動補完", -- src\editor\menu_edit.lua
  ["Auto complete while typing"] = "入力中に自動補完します", -- src\editor\menu_edit.lua
  ["Binary file is shown as read-only as it is only partially loaded."] = "バイナリファイルに読み取れない箇所があったため、読み取り専用になります。", -- src\editor\commands.lua
  ["Bookmark"] = "ブックマーク", -- src\editor\menu_edit.lua
  ["Break execution at the next executed line of code"] = "次に実行するコード行でブレークします", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Breakpoint"] = "ブレークポイント", -- src\editor\menu_project.lua
  ["C&lear Console Window"] = "コンソールウィンドウをクリアー(&L)", -- src\editor\gui.lua
  ["C&lear Output Window"] = "出力ウィンドウをクリアー(&L)", -- src\editor\gui.lua, src\editor\menu_project.lua
  ["C&omment/Uncomment"] = "コメント化/コメント解除(&O)", -- src\editor\menu_edit.lua
  ["Can't evaluate the expression while the application is running."] = "アプリケーションの実行中は式を評価できません。", -- src\editor\debugger.lua
  ["Can't open file '%s': %s"] = "ファイル '%s' を開けません：%s", -- src\editor\inspect.lua, src\editor\outline.lua, src\editor\findreplace.lua, src\editor\package.lua, src\editor\commands.lua
  ["Can't overwrite unsaved file '%s'."] = "未保存ファイル '%s' を上書きできません。", -- src\editor\filetree.lua
  ["Can't process auto-recovery record; invalid format: %s."] = "自動バックアップ記録を処理できません（不正な形式）：%s。", -- src\editor\commands.lua
  ["Can't replace in read-only text."] = "読み取り専用のテキストは置換できません。", -- src\editor\findreplace.lua
  ["Can't run the entry point script ('%s')."] = "エントリーポイントスクリプトを実行できません（'%s'）。", -- src\editor\debugger.lua
  ["Can't start debugger server at %s:%d: %s."] = "デバッガーサーバー %s:%d を起動できません：%s。", -- src\editor\debugger.lua
  ["Can't start debugging for '%s'."] = "'%s' のデバッグを開始できません。", -- src\editor\debugger.lua
  ["Can't start debugging session due to internal error '%s'."] = "内部エラー '%s'  によりデバッグセッションを開始できません。", -- src\editor\debugger.lua
  ["Can't start debugging without an opened file or with the current file not being saved."] = "ファイルを開いていないか未保存の場合は、デバッグを開始できません。", -- src\editor\debugger.lua
  ["Can't stop debugger server as it is not started."] = "起動していないデバッガーサーバーは停止できません。", -- src\editor\debugger.lua
  ["Cancelled by the user."] = "ユーザーがキャンセルしました。", -- src\editor\findreplace.lua
  ["Choose a directory to map"] = "マップするフォルダーを選択", -- src\editor\filetree.lua
  ["Choose a project directory"] = "プロジェクトフォルダーを選択します", -- src\editor\toolbar.lua, src\editor\menu_project.lua, src\editor\filetree.lua
  ["Choose a search directory"] = "検索先フォルダーを選択", -- src\editor\findreplace.lua
  ["Choose..."] = "選択...", -- src\editor\findreplace.lua, src\editor\menu_project.lua, src\editor\filetree.lua
  ["Clear Bookmarks In File"] = "ファイル内のブックマークをクリアー", -- src\editor\markers.lua
  ["Clear Bookmarks In Project"] = "プロジェクト内のブックマークをクリアー", -- src\editor\markers.lua
  ["Clear Breakpoints In File"] = "ファイル内のブレークポイントをクリアー", -- src\editor\markers.lua
  ["Clear Breakpoints In Project"] = "プロジェクト内のブレークポイントをクリアー", -- src\editor\markers.lua
  ["Clear Items"] = "項目をクリアー", -- src\editor\findreplace.lua, src\editor\menu_file.lua
  ["Clear items from this list"] = "一覧の項目をクリアーします", -- src\editor\menu_file.lua
  ["Clear the output window before compiling or debugging"] = "コンパイルまたはデバッグの前に出力ウィンドウをクリアーします", -- src\editor\menu_project.lua
  ["Close &Other Pages"] = "他のページを閉じる(&O)", -- src\editor\gui.lua
  ["Close A&ll Pages"] = "全ページを閉じる(&L)", -- src\editor\gui.lua
  ["Close Search Results Pages"] = "検索結果ページを閉じる", -- src\editor\gui.lua
  ["Close the current editor window"] = "現在のエディターウィンドウを閉じます", -- src\editor\menu_file.lua
  ["Co&ntinue"] = "実行再開(&N)", -- src\editor\menu_project.lua
  ["Col: %d"] = "列:%d", -- src\editor\editor.lua
  ["Command Line Parameters..."] = "コマンドライン引数...", -- src\editor\gui.lua, src\editor\menu_project.lua
  ["Command line parameters"] = "コマンドライン引数", -- src\editor\menu_project.lua
  ["Comment or uncomment current or selected lines"] = "現在行または選択行をコメント化またはコメント解除します", -- src\editor\menu_edit.lua
  ["Compilation error"] = "コンパイルエラー", -- src\editor\commands.lua, src\editor\debugger.lua
  ["Compilation successful; %.0f%% success rate (%d/%d)."] = "コンパイル成功；%.0f%% 成功率（%d/%d）。", -- src\editor\commands.lua
  ["Compile the current file"] = "現在のファイルをコンパイルします", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Complete &Identifier"] = "識別子を補完(&I)", -- src\editor\menu_edit.lua
  ["Complete the current identifier"] = "現在の識別子を補完します", -- src\editor\menu_edit.lua
  ["Consider removing backslash from escape sequence '%s'."] = "エスケープシーケンス '%s' からバックスラッシュ記号を削除してみてください。", -- src\editor\commands.lua
  ["Copy Full Path"] = "フルパスをコピー", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Copy selected text to clipboard"] = "選択中のテキストをクリップボードにコピーします", -- src\editor\menu_edit.lua
  ["Correct &Indentation"] = "インデントの自動修正(&I)", -- src\editor\menu_edit.lua
  ["Couldn't activate file '%s' for debugging; continuing without it."] = "デバッグのためにファイル '%s' をアクティブ化できませんでした。処理は続行します。", -- src\editor\debugger.lua
  ["Create an empty document"] = "空のドキュメントを作成します", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Cu&t"] = "切り取り(&T)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["Cut selected text to clipboard"] = "選択中のテキストをクリップボードに切り取ります", -- src\editor\menu_edit.lua
  ["Debugger server started at %s:%d."] = "デバッガーサーバー %s:%d を起動しました。", -- src\editor\debugger.lua
  ["Debugger server stopped at %s:%d."] = "デバッガーサーバー %s:%d を停止しました。", -- src\editor\debugger.lua
  ["Debugging session completed (%s)."] = "デバッグセッションを完了しました（%s）。", -- src\editor\debugger.lua
  ["Debugging session started in '%s'."] = "デバッグセッションを開始しました（'%s'）。", -- src\editor\debugger.lua
  ["Debugging suspended at '%s:%s' (couldn't activate the file)."] = "'%s:%s' のデバッグを中断しました（ファイルをアクティブ化できません）。", -- src\editor\debugger.lua
  ["Detach &Process"] = "プロセスをデタッチ(&P)", -- src\editor\menu_project.lua
  ["Disable Indexing For '%s'"] = "'%s' を索引化対象から除外", -- src\editor\outline.lua
  ["Do you want to delete '%s'?"] = "'%s' を削除してよろしいですか？", -- src\editor\filetree.lua
  ["Do you want to overwrite it?"] = "上書きしてよろしいですか？", -- src\editor\commands.lua
  ["Do you want to reload it?"] = "再読み込みしてよろしいですか？", -- src\editor\editor.lua
  ["Do you want to save the changes to '%s'?"] = "'%s' に変更を保存してよろしいですか？", -- src\editor\commands.lua
  ["E&xit"] = "終了(&X)", -- src\editor\menu_file.lua
  ["Enable Indexing"] = "索引化を有効にする", -- src\editor\outline.lua
  ["Enter Lua code and press Enter to run it."] = "Lua コードを入力し、Enter キーの押下で実行できます。", -- src\editor\shellbox.lua
  ["Enter command line parameters"] = "コマンドライン引数を入力してください", -- src\editor\menu_project.lua
  ["Enter replacement text"] = "置換テキストを入力してください", -- src\editor\editor.lua
  ["Error while loading API file: %s"] = "API ファイルの読み込み中にエラーが発生しました：%s", -- src\editor\autocomplete.lua
  ["Error while loading configuration file: %s"] = "設定ファイルの読み込み中にエラーが発生しました：%s", -- src\editor\style.lua
  ["Error while processing API file: %s"] = "API ファイルの処理中にエラーが発生しました：%s", -- src\editor\autocomplete.lua
  ["Error while processing configuration file: %s"] = "設定ファイルの処理中にエラーが発生しました：%s", -- src\editor\style.lua
  ["Error"] = "エラー", -- src\editor\package.lua
  ["Evaluate In Console"] = "コンソールで評価", -- src\editor\editor.lua
  ["Execute the current project/file and keep updating the code to see immediate results"] = "現在のプロジェクト/ファイルを実行して、コードの変更を即座に反映し続けます", -- src\editor\menu_project.lua
  ["Execute the current project/file"] = "現在のプロジェクト/ファイルを実行します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Execution error"] = "実行エラー", -- src\editor\debugger.lua
  ["Exit program"] = "プログラムを終了します", -- src\editor\menu_file.lua
  ["File '%s' has been modified on disk."] = "ファイル '%s' がディスク上で変更されました。", -- src\editor\editor.lua
  ["File '%s' has more recent timestamp than restored '%s'; please review before saving."] = "ファイル '%s' のタイムスタンプは、バックアップから復元した '%s' よりも最新です。保存する前によく確認してください。", -- src\editor\commands.lua
  ["File '%s' is missing and can't be recovered."] = "ファイル '%s' が見つかりません。バックアップもありません。", -- src\editor\commands.lua
  ["File '%s' no longer exists."] = "ファイル '%s' は存在しません。", -- src\editor\menu_file.lua, src\editor\editor.lua
  ["File already exists."] = "ファイルがすでに存在しています。", -- src\editor\commands.lua
  ["File history"] = "ファイル履歴", -- src\editor\menu_file.lua
  ["Find &In Files"] = "フォルダー内検索(&I)", -- src\editor\menu_search.lua
  ["Find &Next"] = "次を検索(&N)", -- src\editor\menu_search.lua
  ["Find &Previous"] = "前を検索(&P)", -- src\editor\menu_search.lua
  ["Find and insert library function"] = "ライブラリ関数を検索して挿入します", -- src\editor\menu_search.lua
  ["Find and replace text in files"] = "フォルダー内からテキストを置換します", -- src\editor\menu_search.lua
  ["Find and replace text"] = "テキストを置換します", -- src\editor\toolbar.lua, src\editor\menu_search.lua
  ["Find in files"] = "フォルダー内検索", -- src\editor\toolbar.lua
  ["Find next"] = "次を検索", -- src\editor\toolbar.lua
  ["Find text in files"] = "フォルダー内からテキストを検索します", -- src\editor\menu_search.lua
  ["Find text"] = "テキストを検索します", -- src\editor\toolbar.lua, src\editor\menu_search.lua
  ["Find the earlier text occurence"] = "前の候補を検索します", -- src\editor\menu_search.lua
  ["Find the next text occurrence"] = "次の候補を検索します", -- src\editor\menu_search.lua
  ["Fold or unfold all code folds"] = "すべてのコード折りたたみを切り替えます", -- src\editor\menu_edit.lua
  ["Fold or unfold current line"] = "現在行のコード折りたたみを切り替えます", -- src\editor\menu_edit.lua
  ["Fold/Unfold Current &Line"] = "現在行のコード折りたたみを切り替え(&L)", -- src\editor\menu_edit.lua
  ["Follow symlink subdirectories"] = "Symlink サブフォルダーを追跡する", -- src\editor\toolbar.lua
  ["Formatting page %d..."] = "%d ページ目をフォーマットしています...", -- src\editor\print.lua
  ["Found %d instance."] = "%d 個見つかりました。", -- src\editor\findreplace.lua
  ["Found auto-recovery record and restored saved session."] = "自動バックアップ記録が見つかったため、セッションを復元しました。", -- src\editor\commands.lua
  ["Found match in '%s'."] = "'%s' で一致が見つかりました。", -- src\editor\findreplace.lua
  ["Full &Screen"] = "全画面(&S)", -- src\editor\menu_view.lua
  ["Go To Definition"] = "定義元へ移動", -- src\editor\editor.lua
  ["Go To File..."] = "ファイルへ移動...", -- src\editor\menu_search.lua
  ["Go To Line..."] = "行へ移動...", -- src\editor\menu_search.lua
  ["Go To Next Bookmark"] = "次のブックマークへ移動", -- src\editor\menu_edit.lua
  ["Go To Next Breakpoint"] = "次のブレークポイントへ移動", -- src\editor\menu_project.lua
  ["Go To Previous Bookmark"] = "前のブックマークへ移動", -- src\editor\menu_edit.lua
  ["Go To Previous Breakpoint"] = "前のブレークポイントへ移動", -- src\editor\menu_project.lua
  ["Go To Symbol..."] = "シンボルへ移動...", -- src\editor\menu_search.lua
  ["Go to file"] = "ファイルへ移動します", -- src\editor\menu_search.lua
  ["Go to line"] = "行へ移動します", -- src\editor\menu_search.lua
  ["Go to symbol"] = "シンボルへ移動します", -- src\editor\menu_search.lua
  ["Hide '.%s' Files"] = "'.%s' ファイルを非表示にする", -- src\editor\filetree.lua
  ["Hoist Directory"] = "上のフォルダーへ", -- src\editor\filetree.lua
  ["INS"] = "挿入", -- src\editor\editor.lua
  ["Ignore and don't index symbols from files in the selected directory"] = "選択したフォルダー配下のファイル由来のシンボルを無視して索引化しない", -- src\editor\outline.lua
  ["Ignored error in debugger initialization code: %s."] = "デバッガーの初期化コードで発生したエラーを無視しました：%s。", -- src\editor\debugger.lua
  ["Indexing %d files: '%s'..."] = "%d 個のファイルを索引化しています：'%s'...", -- src\editor\outline.lua
  ["Indexing completed."] = "索引化を完了しました。", -- src\editor\outline.lua
  ["Insert Library Function..."] = "ライブラリ関数の挿入...", -- src\editor\menu_search.lua
  ["Known Files"] = "既知のファイル", -- src\editor\commands.lua
  ["Ln: %d"] = "行:%d", -- src\editor\editor.lua
  ["Local console"] = "ローカルコンソール", -- src\editor\gui.lua, src\editor\shellbox.lua
  ["Lua &Interpreter"] = "Lua インタープリター(&I)", -- src\editor\menu_project.lua
  ["Map Directory..."] = "フォルダーをマップ...", -- src\editor\filetree.lua
  ["Mapped remote request for '%s' to '%s'."] = "リモートフォルダー '%s' を '%s' にマップしました。", -- src\editor\debugger.lua
  ["Markers Window"] = "マーカーウィンドウ", -- src\editor\menu_view.lua
  ["Markers"] = "マーカー", -- src\editor\markers.lua
  ["Match case"] = "大文字と小文字を区別する", -- src\editor\toolbar.lua
  ["Match whole word"] = "単語全体と一致", -- src\editor\toolbar.lua
  ["Mixed end-of-line encodings detected."] = "行末記号の混在を検出しました。", -- src\editor\commands.lua
  ["Navigate"] = "ナビゲート", -- src\editor\menu_search.lua
  ["New &File"] = "ファイルを新規作成(&F)", -- src\editor\filetree.lua
  ["OVR"] = "上書", -- src\editor\editor.lua
  ["Open Containing Folder"] = "親フォルダーを開く", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Open With Default Program"] = "既定のプログラムで開く", -- src\editor\filetree.lua
  ["Open an existing document"] = "既存のドキュメントを開きます", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Open file"] = "ファイルを開く", -- src\editor\commands.lua
  ["Outline Window"] = "アウトラインウィンドウ", -- src\editor\menu_view.lua
  ["Outline"] = "アウトライン", -- src\editor\outline.lua
  ["Output (running)"] = "出力（実行中）", -- src\editor\debugger.lua, src\editor\output.lua
  ["Output (suspended)"] = "出力（一時停止中）", -- src\editor\debugger.lua
  ["Output"] = "出力", -- src\editor\debugger.lua, src\editor\output.lua, src\editor\gui.lua, src\editor\settings.lua
  ["Page Setup..."] = "ページ設定...", -- src\editor\print.lua
  ["Paste text from the clipboard"] = "クリップボードからテキストを貼り付けます", -- src\editor\menu_edit.lua
  ["Preferences"] = "環境設定", -- src\editor\menu_edit.lua
  ["Prepend '!' to force local execution."] = "'!' を前置すると、ローカル実行になります。", -- src\editor\shellbox.lua
  ["Prepend '=' to show complex values on multiple lines."] = "'=' を前置すると、複雑な値を複数行で出力できます。", -- src\editor\shellbox.lua
  ["Press cancel to abort."] = "Cancel を押して中止してください。", -- src\editor\commands.lua
  ["Print the current document"] = "現在のドキュメントを印刷します", -- src\editor\print.lua
  ["Program '%s' started in '%s' (pid: %d)."] = "プログラム '%s' を '%s' から起動しました（pid: %d）。<", -- src\editor\output.lua
  ["Program can't start because conflicting process is running as '%s'."] = "起動中の '%s' とプロセスが衝突したためプログラムを起動できません。", -- src\editor\output.lua
  ["Program completed in %.2f seconds (pid: %d)."] = "プログラムの実行を %.2f 秒で完了しました（pid: %d）。", -- src\editor\output.lua
  ["Program starting as '%s'."] = "プログラム起動コマンド '%s'。", -- src\editor\output.lua
  ["Program stopped (pid: %d)."] = "プログラムが停止しました（pid: %d）。", -- src\editor\debugger.lua
  ["Program unable to run as '%s'."] = "コマンド '%s' でプログラムを実行できませんでした。", -- src\editor\output.lua
  ["Project Directory"] = "プロジェクトフォルダー", -- src\editor\menu_project.lua, src\editor\filetree.lua
  ["Project history"] = "プロジェクト履歴", -- src\editor\menu_file.lua
  ["Project"] = "プロジェクト", -- src\editor\filetree.lua
  ["Project/&FileTree Window"] = "プロジェクト/ファイルツリーウィンドウ(&F)", -- src\editor\menu_view.lua
  ["Provide command line parameters"] = "コマンドライン引数を設定します", -- src\editor\menu_project.lua
  ["Queued %d files to index."] = "%d 個のファイルを索引化します。", -- src\editor\commandbar.lua
  ["R/O"] = "読専", -- src\editor\editor.lua
  ["R/W"] = "読/書", -- src\editor\editor.lua
  ["Re&place In Files"] = "フォルダー内置換(&P)", -- src\editor\menu_search.lua
  ["Re-indent selected lines"] = "選択行を再インデントします", -- src\editor\menu_edit.lua
  ["Reached end of selection and wrapped around."] = "選択範囲末尾に達したら先頭に戻って継続します。", -- src\editor\findreplace.lua
  ["Reached end of text and wrapped around."] = "テキスト末尾に達したら先頭に戻って継続します。", -- src\editor\findreplace.lua
  ["Recent Files"] = "最近使ったファイル", -- src\editor\menu_file.lua
  ["Recent Projects"] = "最近使ったプロジェクト", -- src\editor\menu_file.lua
  ["Redo last edit undone"] = "最後に取り消した編集をやり直します", -- src\editor\menu_edit.lua
  ["Refresh Index"] = "索引を更新", -- src\editor\outline.lua
  ["Refresh Search Results"] = "検索結果を更新", -- src\editor\gui.lua
  ["Refresh indexed symbols from files in the selected directory"] = "選択したフォルダー配下のファイル由来のシンボルの索引を更新", -- src\editor\outline.lua
  ["Refresh"] = "更新", -- src\editor\filetree.lua
  ["Refused a request to start a new debugging session as there is one in progress already."] = "すでに実行中のセッションがあるため、新しいデバッグセッションを開始できませんでした。", -- src\editor\debugger.lua
  ["Regular expression"] = "正規表現", -- src\editor\toolbar.lua
  ["Remote console"] = "リモートコンソール", -- src\editor\shellbox.lua
  ["Rename All Instances"] = "インスタンス名をすべて変更", -- src\editor\editor.lua
  ["Replace All Selections"] = "選択テキストをすべて置換", -- src\editor\editor.lua
  ["Replace all"] = "すべて置換", -- src\editor\toolbar.lua
  ["Replace next instance"] = "次のインスタンスを置換", -- src\editor\toolbar.lua
  ["Replaced %d instance."] = "%d 個のインスタンスを置換しました。", -- src\editor\findreplace.lua
  ["Replaced an invalid UTF8 character with %s."] = "不正な UTF8 文字を %s で置換しました。", -- src\editor\commands.lua
  ["Reset to default layout"] = "既定のレイアウトを復元します", -- src\editor\menu_view.lua
  ["Run As Scratchpad"] = "スクラッチパッドとして実行", -- src\editor\menu_project.lua
  ["Run To Cursor"] = "カーソル行まで実行", -- src\editor\menu_project.lua, src\editor\editor.lua
  ["Run as Scratchpad"] = "スクラッチパッドとして実行します", -- src\editor\toolbar.lua
  ["Run to cursor"] = "カーソル行まで実行します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["S&top Debugging"] = "デバッグ終了(&T)", -- src\editor\menu_project.lua
  ["S&top Process"] = "プロセスを停止(&T)", -- src\editor\menu_project.lua
  ["Save &As..."] = "別名で保存(&A)...", -- src\editor\gui.lua, src\editor\menu_file.lua
  ["Save A&ll"] = "すべて保存(&L)", -- src\editor\menu_file.lua
  ["Save Changes?"] = "変更を保存しますか？", -- src\editor\commands.lua
  ["Save all open documents"] = "すべての開いているドキュメントを保存します", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Save file as"] = "別名で保存", -- src\editor\commands.lua
  ["Save file?"] = "保存しますか？", -- src\editor\commands.lua
  ["Save the current document to a file with a new name"] = "現在のドキュメントに新しい名前を付けてファイルに保存します", -- src\editor\menu_file.lua
  ["Save the current document"] = "現在のドキュメントを保存します", -- src\editor\toolbar.lua, src\editor\menu_file.lua
  ["Saved auto-recover at %s."] = "%s にバックアップを自動保存しました。", -- src\editor\commands.lua
  ["Scratchpad error"] = "スクラッチパッドエラー", -- src\editor\debugger.lua
  ["Search direction"] = "検索方向", -- src\editor\toolbar.lua
  ["Search in mapped directories"] = "マップしたフォルダー内を検索", -- src\editor\toolbar.lua
  ["Search in selection"] = "選択範囲内で検索", -- src\editor\toolbar.lua
  ["Search in subdirectories"] = "サブフォルダーから検索", -- src\editor\toolbar.lua
  ["Searching for '%s'."] = "'%s' を検索します。", -- src\editor\findreplace.lua
  ["Searching in '%s'."] = "'%s' を検索しています。", -- src\editor\findreplace.lua
  ["Sel: %d/%d"] = "選択:%d文字/%d箇所", -- src\editor\editor.lua
  ["Select &All"] = "すべて選択(&A)", -- src\editor\gui.lua, src\editor\editor.lua, src\editor\menu_edit.lua
  ["Select And Find Next"] = "選択して次を検索", -- src\editor\menu_search.lua
  ["Select And Find Previous"] = "選択して前を検索", -- src\editor\menu_search.lua
  ["Select all text in the editor"] = "エディター上のテキストをすべて選択します", -- src\editor\menu_edit.lua
  ["Select the word under cursor and find its next occurrence"] = "カーソル下の語句を選択して次候補を検索します", -- src\editor\menu_search.lua
  ["Select the word under cursor and find its previous occurrence"] = "カーソル下の語句を選択して前候補を検索します", -- src\editor\menu_search.lua
  ["Set As Start File"] = "実行起点ファイルに設定", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Set From Current File"] = "現在のファイルを基準に設定", -- src\editor\menu_project.lua
  ["Set To Project Directory"] = "プロジェクトフォルダーに設定", -- src\editor\findreplace.lua
  ["Set To Selected Directory"] = "選択したフォルダーに設定", -- src\editor\filetree.lua
  ["Set project directory from current file"] = "現在のファイルを基準にプロジェクトフォルダーを設定します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Set project directory to the selected one"] = "選択したフォルダーをプロジェクトフォルダーに設定します", -- src\editor\filetree.lua
  ["Set search directory"] = "検索フォルダーに設定", -- src\editor\toolbar.lua
  ["Set the interpreter to be used"] = "使用するインタープリターを設定します", -- src\editor\menu_project.lua
  ["Set the project directory to be used"] = "使用するプロジェクトフォルダーを設定します", -- src\editor\menu_project.lua, src\editor\filetree.lua
  ["Settings: System"] = "設定：システム", -- src\editor\menu_edit.lua
  ["Settings: User"] = "設定：ユーザー", -- src\editor\menu_edit.lua
  ["Show &Tooltip"] = "ツールチップを表示(&T)", -- src\editor\menu_edit.lua
  ["Show All Files"] = "ファイルをすべて表示", -- src\editor\filetree.lua
  ["Show Hidden Files"] = "隠しファイルを表示", -- src\editor\filetree.lua
  ["Show all files"] = "ファイルをすべて表示します", -- src\editor\filetree.lua
  ["Show context"] = "コンテキストを表示", -- src\editor\toolbar.lua
  ["Show files previously hidden"] = "隠しファイルを表示します", -- src\editor\filetree.lua
  ["Show multiple result windows"] = "結果ウィンドウを複数表示", -- src\editor\toolbar.lua
  ["Show tooltip for current position; place cursor after opening bracket of function"] = "カーソルの現在位置にツールチップを表示します。また関数呼び出しの開き括弧を入力すると、自動表示されます", -- src\editor\menu_edit.lua
  ["Show/Hide the status bar"] = "ステータスバーの表示を切り替えます", -- src\editor\menu_view.lua
  ["Show/Hide the toolbar"] = "ツールバーの表示を切り替えます", -- src\editor\menu_view.lua
  ["Sort By Name"] = "名前で並べ替え", -- src\editor\outline.lua
  ["Sort selected lines"] = "選択行を並べ替えます", -- src\editor\menu_edit.lua
  ["Source"] = "ソース", -- src\editor\menu_edit.lua
  ["Stack"] = "スタック", -- src\editor\debugger.lua
  ["Start &Debugging"] = "デバッグ開始", -- src\editor\menu_project.lua
  ["Start or continue debugging"] = "デバッグを開始または再開します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step &Into"] = "ステップイン(&I)", -- src\editor\menu_project.lua
  ["Step &Over"] = "ステップオーバー(&O)", -- src\editor\menu_project.lua
  ["Step O&ut"] = "ステップアウト(&U)", -- src\editor\menu_project.lua
  ["Step into"] = "ステップインします", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step out of the current function"] = "現在の関数からステップアウトします", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Step over"] = "ステップオーバーします", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Stop debugging and continue running the process"] = "デバッグを終了してプロセスの実行を継続します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Stop the currently running process"] = "現在実行中のプロセスを停止します", -- src\editor\toolbar.lua, src\editor\menu_project.lua
  ["Switch to or from full screen mode"] = "全画面モードを切り替えます", -- src\editor\menu_view.lua
  ["Symbol Index"] = "シンボル索引", -- src\editor\outline.lua
  ["Text not found."] = "テキストが見つかりませんでした。", -- src\editor\findreplace.lua
  ["The API file must be located in a subdirectory of the API directory."] = "API ファイルは API フォルダーのサブフォルダー内に配置する必要があります。", -- src\main.lua
  ["Toggle Bookmark"] = "ブックマークを切り替え", -- src\editor\markers.lua, src\editor\menu_edit.lua
  ["Toggle Breakpoint"] = "ブレークポイントを切り替え", -- src\editor\markers.lua, src\editor\menu_project.lua
  ["Toggle bookmark"] = "ブックマークを切り替えます", -- src\editor\toolbar.lua, src\editor\menu_edit.lua, src\editor\markers.lua
  ["Toggle breakpoint"] = "ブレークポイントを切り替えます", -- src\editor\markers.lua, src\editor\toolbar.lua
  ["Tr&ace"] = "トレース(&A)", -- src\editor\menu_project.lua
  ["Trace execution showing each executed line"] = "実行行を表示しながらトレース実行します", -- src\editor\menu_project.lua
  ["Unable to create directory '%s'."] = "フォルダー '%s' を作成できません。", -- src\editor\filetree.lua
  ["Unable to create file '%s'."] = "ファイル '%s' を作成できません。", -- src\editor\filetree.lua
  ["Unable to delete directory '%s': %s"] = "フォルダー '%s' を削除できません：%s", -- src\editor\filetree.lua
  ["Unable to delete file '%s': %s"] = "ファイル '%s' を削除できません：%s", -- src\editor\filetree.lua
  ["Unable to load file '%s'."] = "ファイル '%s' を開けません。", -- src\editor\commands.lua
  ["Unable to rename file '%s'."] = "ファイル '%s' の名前を変更できません。", -- src\editor\filetree.lua
  ["Unable to save file '%s': %s"] = "ファイル '%s' を保存できません：%s", -- src\editor\commands.lua
  ["Unable to stop program (pid: %d), code %d."] = "プログラムを停止できません（pid: %d, code %d）。", -- src\editor\debugger.lua
  ["Undo last edit"] = "最後の編集を取り消します", -- src\editor\menu_edit.lua
  ["Unhoist Directory"] = "下のフォルダーへ", -- src\editor\filetree.lua
  ["Unmap Directory"] = "フォルダーをマップ解除", -- src\editor\filetree.lua
  ["Unset '%s' As Start File"] = "'%s' の実行起点ファイル設定を解除", -- src\editor\gui.lua, src\editor\filetree.lua
  ["Updated %d file."] = "%d 個のファイルを更新しました。", -- src\editor\findreplace.lua
  ["Updating symbol index and settings..."] = "シンボル索引と設定を更新しています...", -- src\editor\outline.lua
  ["Use %s to close."] = "%s で閉じます。", -- src\editor\findreplace.lua
  ["Use '%s' to see full description."] = "%s ですべて表示します。", -- src\editor\editor.lua
  ["Use '%s' to show line endings and '%s' to convert them."] = "行末記号は '%s' で表示できます。また '%s' で一括変換できます。", -- src\editor\commands.lua
  ["Use 'clear' to clear the shell output and the history."] = "'clear' コマンドでシェルの出力と履歴を消去できます。", -- src\editor\shellbox.lua
  ["Use 'reset' to clear the environment."] = "'reset' コマンドで環境を初期化できます。", -- src\editor\shellbox.lua
  ["Use Shift-Enter for multiline code."] = "Shift + Enter で複数行のコードを入力できます。", -- src\editor\shellbox.lua
  ["View the markers window"] = "マーカーウィンドウを表示します", -- src\editor\menu_view.lua
  ["View the outline window"] = "アウトラインウィンドウを表示します", -- src\editor\menu_view.lua
  ["View the output/console window"] = "出力/コンソールウィンドウを表示します", -- src\editor\menu_view.lua
  ["View the project/filetree window"] = "プロジェクト/ファイルツリーウィンドウを表示します", -- src\editor\menu_view.lua
  ["View the stack window"] = "スタックウィンドウを表示します", -- src\editor\toolbar.lua, src\editor\menu_view.lua
  ["View the watch window"] = "ウォッチウィンドウを表示します", -- src\editor\toolbar.lua, src\editor\menu_view.lua
  ["Watch"] = "ウォッチ", -- src\editor\debugger.lua
  ["Welcome to the interactive Lua interpreter."] = "対話式 Lua インタープリターへようこそ。", -- src\editor\shellbox.lua
  ["Wrap around"] = "周回する", -- src\editor\toolbar.lua
  ["You must save the program first."] = "先にプログラムを保存する必要があります。", -- src\editor\commands.lua
  ["Zoom In"] = "ズームイン", -- src\editor\menu_view.lua
  ["Zoom Out"] = "ズームアウト", -- src\editor\menu_view.lua
  ["Zoom to 100%"] = "100% 表示", -- src\editor\menu_view.lua
  ["Zoom"] = "ズーム", -- src\editor\menu_view.lua
  ["on line %d"] = "発生行 %d", -- src\editor\debugger.lua, src\editor\editor.lua, src\editor\commands.lua
  ["traced %d instruction"] = "%d 個のインストラクションをトレースしました", -- src\editor\debugger.lua
  ["unknown error"] = "不明なエラー", -- src\editor\debugger.lua
}