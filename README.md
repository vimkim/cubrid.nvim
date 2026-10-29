# CUBRID for Neovim

[English](README.en.md) | 한국어

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim)은 `.sql`과 `.csql` 파일에 구문 색상과 들여쓰기를 적용하고, 별도로 설치한 CUBRID 언어 서버로 자동 완성과 진단을 제공합니다. SQL을 실행하거나 데이터베이스에 접속하지 않습니다. Neovim 0.12.5에서 테스트했습니다.

## LazyVim 또는 lazy.nvim으로 설치

Python 3.10 이상과 선택적 `lsp` 의존성을 포함한 공유 언어 서버를 설치하세요. [공유 엔진 설치 안내](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md)를 참고하세요. 서버는 플러그인과 별도로 설치합니다. 엄격한 구문 진단에는 검증된 네이티브 파서 워커와 일치하는 런타임도 별도로 필요합니다. 키워드 자동 완성에는 필요하지 않습니다.

LazyVim에서는 `~/.config/nvim/lua/plugins/cubrid.lua`와 같은 파일에 다음 설정을 추가하세요. lazy.nvim을 직접 사용한다면 lazy.nvim 설정에 이 spec을 추가하세요. `lazy = false`는 시작할 때 `.sql`과 `.csql` 파일 형식을 등록합니다.

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

플러그인은 Neovim의 `PATH`에서 `cubrid-language-server`를 찾습니다. 로컬 소스에서 `just sync`로 설치한 패키지의 메타데이터를 읽고 기록된 소스 디렉터리의 `native/parser-worker/build/parser-worker`를 찾습니다. 인접한 `manifest.json`의 `runtimePrefix`에서 런타임 경로를 읽습니다. `just sync`는 네이티브 워커를 빌드하지 않습니다. [공유 엔진 설치 안내](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md)를 참고하세요.

휠이나 패키지 인덱스에서 설치했거나 로컬 네이티브 빌드가 없다면 신뢰하는 Lua 설정에 절대 경로 `parser_worker`와 `runtime_prefix`를 함께 지정하세요. 절대 경로 `server_path`도 지정할 수 있습니다. 검색에 실패하면 키워드 자동 완성은 사용할 수 있으며 서버가 런타임 부재를 진단합니다. `:CubridDoctor` 또는 `:checkhealth cubrid`로 설치와 네이티브 진단을 확인하세요.

서버가 `PATH`에 없다면 `opts`의 `server_path`에 절대 경로를 지정하세요. 예를 들면 다음과 같습니다.

```lua
opts = {
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
}
```

`.sql`과 `.csql`은 기본적으로 `cubrid` 파일 형식으로 감지됩니다. `.csql`만 사용하려면 플러그인 spec의 `opts`를 다음과 같이 설정하세요. 기존 버퍼는 다시 열어야 합니다.

```lua
opts = { file_extensions = { '.csql' } }
```

`.sql`만 선택하려면 `{ '.sql' }`, 자동 연결을 모두 끄려면 `{}`를 사용하세요. 목록은 기본값을 대체하며, 확장자는 소문자로 지정합니다. 파일 이름의 대소문자는 구분하지 않습니다. 기존 `sql` 옵션은 오류가 발생합니다. `file_extensions`로 변경하세요.

다른 파일 형식이나 LSP 클라이언트가 감지되면 경고합니다. 파일 형식 규칙을 수정하거나 서버 하나를 선택하세요. 자동 연결을 끄려면 `file_extensions`에서 해당 확장자를 제거하고 파일을 다시 여세요. 서버가 없으면 설치하거나 신뢰하는 `server_path`를 설정한 뒤 `:CubridRestart`를 실행하세요.

이 플러그인은 알파 버전입니다. 서버는 지원하지 않는 구문 범위와 네이티브 런타임 오류를 진단으로 표시합니다. 진단이 없더라도 모든 SQL이 검증된 것은 아닙니다. 색상과 들여쓰기는 어휘 기반으로 적용합니다.

삽입 모드에서 `CTRL-X CTRL-O`를 누르고 `CTRL-N`으로 항목을 선택한 다음 `CTRL-Y`로 적용합니다. CUBRID 클라이언트가 연결된 동안 플러그인이 버퍼의 `omnifunc`를 사용합니다. 연결이 끝나면 이전 값을 복원하며, 사용자가 바꾼 값은 유지합니다. CTRL-Y는 커서 뒤의 텍스트를 포함하여 지원하는 한 줄 편집의 전체 범위를 적용합니다. Space나 Escape로 메뉴를 닫으면 Neovim의 미리보기 접미사가 버퍼에 남을 수 있습니다. 여러 줄 편집과 그 밖의 지원하지 않는 완성 항목은 알림으로 표시하며 부분 메뉴를 열지 않습니다.

## 로컬 설치

압축 파일을 Neovim의 패키지 디렉터리에 풉니다. 경로와 서버 실행 파일을 실제 설치 위치로 바꿉니다.

```sh
mkdir -p ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
tar -xzf cubrid.nvim-alpha.tar.gz -C ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
```

Neovim을 시작하고 `:helptags ALL`을 실행하여 도움말을 색인합니다. 위 안내에 따라 신뢰하는 사용자 Lua에서 플러그인을 설정하세요.

Lazy.nvim에서 로컬 설치를 사용할 수도 있습니다. 경로를 실제 위치로 바꾸세요.

```lua
{
  dir = '/absolute/path/to/cubrid.nvim',
  lazy = false,
  config = function() require('cubrid').setup({ file_extensions = { '.sql', '.csql' } }) end,
}
```

## 스키마와 명령

`schema_snapshot`을 생략하면 각 파일의 프로젝트 설정에서 스냅샷을 찾습니다. 절대 경로를 지정하면 모든 파일에 적용합니다. `vim.NIL`은 스키마를 비활성화합니다. `:CubridReloadSchema`는 스냅샷을 다시 읽고 파일별 결과와 오래된 데이터 상태를 알립니다. `:CubridRestart`는 서버를 다시 시작합니다. `setup`을 다시 호출할 때는 유지할 옵션을 모두 전달합니다.

서버 하나가 여러 디렉터리의 파일을 처리합니다. 각 파일의 프로젝트 메타데이터는 서버가 따로 찾습니다. Neovim 0.12.5의 이름 없는 버퍼 URI는 `file://`입니다. 현재 서버는 시작 디렉터리의 상위 디렉터리부터 프로젝트 메타데이터를 찾습니다. 자세한 설정과 제한은 `:help cubrid`를 참조하세요.
