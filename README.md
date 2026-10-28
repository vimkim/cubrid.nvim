# CUBRID for Neovim

[English](README.en.md) | 한국어

이 플러그인은 `.csql` 파일에 구문 색상과 들여쓰기를 적용하고, 별도로 설치한 CUBRID 언어 서버로 자동 완성과 진단을 제공합니다. SQL을 실행하거나 데이터베이스에 접속하지 않습니다. Neovim 0.12.5에서 테스트했습니다.

## 로컬 설치

압축 파일을 Neovim의 패키지 디렉터리에 풉니다. 경로와 서버 실행 파일을 실제 설치 위치로 바꿉니다.

```sh
mkdir -p ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
tar -xzf cubrid.nvim-alpha.tar.gz -C ~/.local/share/nvim/site/pack/local/start/cubrid.nvim
```

Neovim을 시작하고 `:helptags ALL`을 실행하여 도움말을 색인합니다. 신뢰하는 사용자 설정의 Lua 코드에서 설정합니다.

```lua
require('cubrid').setup({
  server_path = '/absolute/path/to/cubrid-language-server',
  parser_worker = '/absolute/path/to/parser-worker',
  runtime_prefix = '/absolute/path/to/cubrid/runtime',
})
```

서버 경로를 생략하면 Neovim 프로세스의 `PATH`에서 `cubrid-language-server`를 찾습니다. `parser_worker`와 `runtime_prefix`는 함께 지정합니다. 지정하지 않으면 런타임 부재 진단이 표시되지만 키워드 자동 완성은 사용할 수 있습니다. 서버와 네이티브 런타임은 별도로 설치해야 합니다. [공유 엔진 설치 안내](https://github.com/vimkim/cubrid-language-tools/blob/main/docs/install.md)를 참고하세요.

`.sql` 파일도 사용하려면 `sql = true`를 설정하고 파일을 다시 엽니다. 기존 SQL 파일 형식은 기본적으로 유지됩니다. 삽입 모드에서 `CTRL-X CTRL-O`를 누르고 `CTRL-N`으로 항목을 선택한 다음 `CTRL-Y`로 적용합니다. CUBRID 클라이언트가 연결된 동안 플러그인이 버퍼의 `omnifunc`를 사용합니다. 연결이 끝나면 이전 값을 복원하며, 사용자가 바꾼 값은 유지합니다. CTRL-Y는 커서 뒤의 텍스트를 포함하여 지원하는 한 줄 편집의 전체 범위를 적용합니다. Space나 Escape로 메뉴를 닫으면 Neovim의 미리보기 접미사가 버퍼에 남을 수 있습니다. 여러 줄 편집과 그 밖의 지원하지 않는 완성 항목은 알림으로 표시하며 부분 메뉴를 열지 않습니다.

## 스키마와 명령

`schema_snapshot`을 생략하면 각 파일의 프로젝트 설정에서 스냅샷을 찾습니다. 절대 경로를 지정하면 모든 파일에 적용합니다. `vim.NIL`은 스키마를 비활성화합니다. `:CubridReloadSchema`는 스냅샷을 다시 읽고 파일별 결과와 오래된 데이터 상태를 알립니다. `:CubridRestart`는 서버를 다시 시작합니다. `setup`을 다시 호출할 때는 유지할 옵션을 모두 전달합니다.

서버 하나가 여러 디렉터리의 파일을 처리합니다. 각 파일의 프로젝트 메타데이터는 서버가 따로 찾습니다. Neovim 0.12.5의 이름 없는 버퍼 URI는 `file://`입니다. 현재 서버는 시작 디렉터리의 상위 디렉터리부터 프로젝트 메타데이터를 찾습니다. 자세한 설정과 제한은 `:help cubrid`를 참조하세요.
