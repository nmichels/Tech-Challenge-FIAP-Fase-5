# README

A versão utilizada do ruby é a 3.2.5. Recomenda-se um gerenciador de versão para instalação do ruby, exemplo rbenv. Após instalado rbenv, é possível adicionar a versão do ruby:
```rbenv install 3.2.5```

### Instalar as dependências
```
gem install bundler
bundle install
```

### Criar e configurar banco de dados:
```
bundle exec rake db:create
bundle exec rake db:migrate
```

### Rodar webserver:
```bundle exec rails s```

### Inicializar redis (necessário para o sidekiq):
```docker compose up```

### Rodar background jobs:
```bundle exec sidekiq```
