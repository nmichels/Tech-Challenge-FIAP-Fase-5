# README

A versão utilizada do ruby é a 3.2.5. Recomenda-se um gerenciador de versão para instalação do ruby, exemplo rbenv. Após instalado rbenv, é possível adicionar a versão do ruby:
```rbenv install 3.2.5```

Para as dependências de frontend, recomenda-se a instalação do NodeJS.
A aplicação foi desenvolvida e testada utilizando a versão v26.0.0

### Processamento de imagens
O pacote libvips é necessário para o correto processamento de imagens.
Instalação no linux (Debian based):
```apt install libvips```

Caso esteja utilizando homebrew para Linux ou MacOS:
```brew install vips```

### Instalar as dependências
```
gem install bundler
bundle install
npm install
```

### Criar e configurar banco de dados:
```
bundle exec rake db:create
bundle exec rake db:migrate
```

### Inicializar redis:
```docker compose up```

### Rodar webserver:
```bundle exec rails s```

### Rodar background jobs (Análise LLM):
```bundle exec sidekiq```

### Arquivos Markdown
Para melhor visualização no navegador dos resultados em markdown, recomenda-se o uso de extensões como Markdown Viewer do Google Chrome
