# CUBRID for Neovim

[English](README.en.md) | 한국어

[cubrid.nvim](https://github.com/vimkim/cubrid.nvim)은 `.sql`과 `.csql` 파일에 구문 색상과 들여쓰기를 적용하고, 별도로 설치한 CUBRID 언어 서버로 자동 완성과 진단을 제공합니다. SQL을 실행하거나 데이터베이스에 접속하지 않습니다. Neovim 0.12.5에서 테스트했습니다.

## 언어 지원과 업그레이드

공유 서버가 자동 완성, 구문 진단, 보수적인 `CUBRID-A` 작성 경고를 담당합니다. SHOW와 옵티마이저 힌트의 자동 완성 범위는 네이티브 검사 범위보다 넓습니다. 작성 경고를 수정한 뒤에도 지원 범위 밖이라는 진단은 남을 수 있습니다.

현재 코어의 검증 범위는 Linux x86-64의 `cubrid-11.5.0.2704-cc94778` 프로필과 `bounded-query-dml-schema-engineer-ordered-v4` 리비전입니다. 최상위 리터럴 `SELECT` 바로 뒤에 인수 없는 `/*+ ORDERED */` 하나를 허용합니다. 이 형태에서는 `FROM`, 조인, 다른 힌트를 지원하지 않습니다. 네이티브 SHOW 검사는 `SHOW TRACE`만 지원합니다. 정확한 제한은 [검증 범위 문서](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/coverage.md)를 참고하세요. SQL 포맷팅과 의미·스타일 린트는 향후 작업입니다.

v4로 업그레이드할 때는 일치하는 코어와 네이티브 워커, 매니페스트, 검증된 런타임을 함께 설치하세요. [공유 엔진 설치 안내](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md)를 따르세요. 이 플러그인을 업데이트하거나 `just sync`를 실행해도 워커를 다시 빌드하지 않습니다. v3 워커는 v4 범위를 제공하지 않습니다. Python 휠에는 네이티브 자산이 없으며, `--version`의 `0.1.0.dev0`만으로는 소스 커밋이나 검증 범위 리비전을 알 수 없습니다.

[인수 증거](docs/acceptance.md#current-status-and-evidence-scope)는 이전 Neovim, Blink, 격리된 LazyVim 검증과 현재 코어 범위를 구분합니다. 해당 에디터 검증은 이전 엔진을 사용했습니다. 새로운 v4 검증이나 개인 프로필 검증을 뜻하지 않습니다.

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

## Neovim 기본 LSP 설정 사용

`setup()`은 함께 제공하는 `lsp/cubrid.lua` 설정을 활성화합니다. Neovim이 연결과 서버 프로세스를 관리합니다. `vim.lsp.enable('cubrid')`를 다시 호출해도 기본 클라이언트를 재사용합니다. nvim-lspconfig나 Blink는 필수 의존성이 아닙니다.

직접 활성화하려면 파일을 열기 전에 신뢰하는 사용자 Lua 설정에 다음 코드를 추가하세요.

```lua
require('cubrid').setup({ auto_start = false })
vim.lsp.config('cubrid', {
  cmd = { '/absolute/path/to/cubrid-language-server' },
  settings = { cubrid = { schemaSnapshot = vim.NIL } },
})
vim.lsp.enable('cubrid')
```

`auto_start = false`는 자동 활성화를 생략합니다. 외부에서 활성화한 설정이나 실행 중인 클라이언트를 끄지는 않습니다. 중지하려면 `vim.lsp.enable('cubrid', false)`를 호출하세요. `:CubridRestart`는 기존 클라이언트를 중지한 뒤 설정을 다시 활성화합니다.

`setup()` 없이도 `cubrid` 파일 형식인 버퍼에서 `vim.lsp.enable('cubrid')`를 사용할 수 있습니다. 직접 파일 형식 규칙을 추가하거나 `:setfiletype cubrid`를 실행하세요. 확장자의 자동 연결은 `setup()`이 설정합니다.

`cmd`, `capabilities`, `on_attach`, `settings`는 `setup()` 전후 어느 쪽에서든 기본 LSP API로 지정할 수 있습니다. 활성화하거나 CUBRID 버퍼를 열기 전에 지정하세요. 기본 LSP 설정 변경은 새 클라이언트에 적용되므로 실행 중인 서버에는 `:CubridRestart`로 반영합니다. Neovim의 병합 순서에 따라 `vim.lsp.config('cubrid', ...)`가 런타임 설정과 `vim.lsp.config('*', ...)`보다 우선합니다. 나중의 기본 LSP 설정 호출은 앞선 호출과 병합됩니다.

서버별 `settings.cubrid` 값은 해당 Lua setup 옵션보다 우선합니다. `setup()`을 다시 호출하면 생략한 setup 옵션은 제거되지만 기본 LSP API에서 지정한 값은 유지됩니다. 초기화 옵션과 이후 설정 알림에는 유효한 CUBRID 설정 전체를 보냅니다.

플러그인의 `before_init`은 설정을 준비하고 `on_exit`는 실패를 알립니다. 둘 중 하나를 재정의할 때는 기존 콜백도 호출하세요. `on_attach`는 사용자 키 매핑에 사용할 수 있습니다. 수동 완성 기능은 별도의 연결 이벤트로 관리합니다.

기본 루트는 최초 setup 또는 기본 LSP 설정 로드 시점의 작업 디렉터리입니다. 디렉터리를 바꿔도 클라이언트 하나를 유지합니다. `root_dir` 또는 루트 콜백을 직접 지정하면 루트별 클라이언트를 사용할 수 있습니다. 이 경우 `:CubridReloadSchema`는 현재 버퍼의 클라이언트를 사용하고 `:CubridRestart`는 CUBRID 클라이언트를 모두 다시 시작합니다.

## LazyVim과 Blink 사용

`lua/plugins/cubrid.lua`에 로컬 플러그인 설정을 추가하고 체크아웃 경로를 실제 위치로 바꾸세요. LazyVim의 기존 LSP 설정과 완성 기능을 사용합니다.

```lua
return {
  {
    dir = '/absolute/path/to/cubrid.nvim',
    lazy = false,
    opts = { auto_start = false },
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        cubrid = { mason = false },
      },
    },
  },
}
```

LazyVim이 `cubrid`를 설정하고 활성화합니다. `mason = false`는 별도로 설치한 서버를 사용하게 합니다. 별도의 `vim.lsp.start()` 호출을 추가하지 마세요. 기본 LSP 옵션은 `servers.cubrid` 아래에 지정합니다. Blink는 일반 `lsp` 소스를 사용하며 CUBRID 전용 완성 소스가 필요하지 않습니다. LazyVim 외부에서는 `require('blink.cmp').get_lsp_capabilities()`를 기본 LSP의 `capabilities`에 전달할 수 있습니다. `CTRL-X CTRL-O` 수동 완성도 계속 사용할 수 있습니다.

SHOW와 힌트 작성 지원이 포함된 공유 서버는 SHOW 명령, 옵티마이저 힌트, `CUBRID-A` 작성 경고를 제공합니다. 플러그인은 서버 결과를 전달합니다. 작성 경고를 수정해도 네이티브 검증 범위 밖이라는 경고는 남을 수 있습니다. 진단이 없다는 사실이 모든 SQL의 유효성을 보장하지는 않습니다.

테스트한 플랫폼은 Linux의 Neovim 0.12.5입니다. 플러그인 테스트는 이전 버전이나 LazyVim 배포판 전체의 시작 과정을 검증하지 않습니다. 별도의 격리된 LazyVim 검증은 인수 보고서에 기록된 설정을 대상으로 합니다. 설치 아티팩트와 별도 완성 검증 결과는 [인수 증거](docs/acceptance.md)를 참조하세요.

## 스키마와 명령

`schema_snapshot`을 생략하면 각 파일의 프로젝트 설정에서 스냅샷을 찾습니다. 절대 경로를 지정하면 모든 파일에 적용합니다. `vim.NIL`은 스키마를 비활성화합니다. `:CubridReloadSchema`는 스냅샷을 다시 읽고 파일별 결과와 오래된 데이터 상태를 알립니다. `:CubridRestart`는 서버를 다시 시작합니다. `setup`을 다시 호출할 때는 유지할 옵션을 모두 전달합니다.

기본 설정에서는 서버 하나가 여러 디렉터리의 파일을 처리합니다. 각 파일의 프로젝트 메타데이터는 서버가 따로 찾습니다. Neovim 0.12.5의 이름 없는 버퍼 URI는 `file://`입니다. 현재 서버는 기본 초기화 루트의 상위 디렉터리부터 프로젝트 메타데이터를 찾습니다. 자세한 설정과 제한은 `:help cubrid`를 참조하세요.
