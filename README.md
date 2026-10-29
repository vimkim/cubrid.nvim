# CUBRID for Neovim

[English](README.en.md) | 한국어

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim)은 `.csql` 파일에 구문 색상과 들여쓰기를 적용하고, 별도로 설치한 CUBRID 언어 서버로 자동 완성과 진단을 제공합니다. SQL을 실행하거나 데이터베이스에 접속하지 않습니다. Neovim 0.12.5에서 테스트했습니다.

## LazyVim 또는 lazy.nvim으로 설치

Python 3.10 이상과 선택적 `lsp` 의존성을 포함한 공유 언어 서버를 설치하세요. [공유 엔진 설치 안내](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md)를 참고하세요. 서버는 플러그인과 별도로 설치합니다. 엄격한 구문 진단에는 검증된 네이티브 파서 워커와 일치하는 런타임도 별도로 필요합니다. 키워드 자동 완성에는 필요하지 않습니다.

LazyVim에서는 `~/.config/nvim/lua/plugins/cubrid.lua`와 같은 파일에 다음 설정을 추가하세요. lazy.nvim을 직접 사용한다면 lazy.nvim 설정에 이 spec을 추가하세요. `lazy = false`는 시작할 때 `.csql` 파일 형식을 등록합니다.

```lua
return {
  {
    'vimkim/cubrid.nvim',
    lazy = false,
    main = 'cubrid',
    opts = {},
  },
}
```

설정 방법은 [LazyVim 플러그인 설정](https://www.lazyvim.org/configuration/plugins)과 [lazy.nvim spec 사용법](https://lazy.folke.io/spec)을 참고하세요. 별도의 nvim-lspconfig 설정이나 Blink 소스는 필요하지 않습니다.

기본적으로 Neovim의 `PATH`에서 `cubrid-language-server`를 찾습니다. 서버가 `PATH`에 없다면 `opts`의 `server_path`에 절대 경로를 지정하세요. 체크아웃의 `.venv`에 설치했다면 `.venv/bin/cubrid-language-server`의 절대 경로를 사용하세요. 엄격한 구문 진단을 사용하려면 검증된 워커와 일치하는 런타임의 절대 경로를 `parser_worker`와 `runtime_prefix`에 함께 지정하세요. 예를 들면 다음과 같습니다.

```lua
opts = {
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
}
```

네이티브 워커와 런타임이 없으면 진단에 런타임 부재가 표시되지만 키워드 자동 완성은 사용할 수 있습니다. 플러그인과 서버에는 런타임이 포함되지 않습니다.

`.sql` 파일도 사용하려면 `sql = true`를 설정하고 파일을 다시 엽니다. 기존 SQL 파일 형식은 기본적으로 유지됩니다. 삽입 모드에서 `CTRL-X CTRL-O`를 누르고 `CTRL-N`으로 항목을 선택한 다음 `CTRL-Y`로 적용합니다. CUBRID 클라이언트가 연결된 동안 플러그인이 버퍼의 `omnifunc`를 사용합니다. 연결이 끝나면 이전 값을 복원하며, 사용자가 바꾼 값은 유지합니다. CTRL-Y는 커서 뒤의 텍스트를 포함하여 지원하는 한 줄 편집의 전체 범위를 적용합니다. Space나 Escape로 메뉴를 닫으면 Neovim의 미리보기 접미사가 버퍼에 남을 수 있습니다. 여러 줄 편집과 그 밖의 지원하지 않는 완성 항목은 알림으로 표시하며 부분 메뉴를 열지 않습니다.

## 스키마와 명령

`schema_snapshot`을 생략하면 각 파일의 프로젝트 설정에서 스냅샷을 찾습니다. 절대 경로를 지정하면 모든 파일에 적용합니다. `vim.NIL`은 스키마를 비활성화합니다. `:CubridReloadSchema`는 스냅샷을 다시 읽고 파일별 결과와 오래된 데이터 상태를 알립니다. `:CubridRestart`는 서버를 다시 시작합니다. `setup`을 다시 호출할 때는 유지할 옵션을 모두 전달합니다.

서버 하나가 여러 디렉터리의 파일을 처리합니다. 각 파일의 프로젝트 메타데이터는 서버가 따로 찾습니다. Neovim 0.12.5의 이름 없는 버퍼 URI는 `file://`입니다. 현재 서버는 시작 디렉터리의 상위 디렉터리부터 프로젝트 메타데이터를 찾습니다. 자세한 설정과 제한은 `:help cubrid`를 참조하세요.
