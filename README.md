# atom

## Instruções para rodar

### Construa e inicie os contêineres:

```docker-compose up --build```

### Acesse o AtoM via navegador:

```Abra o navegador e vá para http://localhost:8081```

### Configuração do Banco de Dados:

Acesse o contêiner do banco de dados para criar o banco de dados e o usuário (caso necessário):

```docker exec -it <nome_do_container_db> mysql -u root -p```

Execute os comandos SQL para criar o banco de dados e o usuário (se necessário).

Finalizar Configuração do AtoM:

### Acesse o contêiner do AtoM:

```docker exec -it <nome_do_container_atom> bash```

### Execute o instalador do AtoM:



```cd /usr/share/nginx/atom```
```php symfony tools:install```

### Reinicie os serviços, se necessário:


```docker-compose restart```

Isso deve configurar o ambiente necessário para rodar o AtoM usando Docker e Docker Compose.