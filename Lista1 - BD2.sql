--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Debian 16.3-1.pgdg120+1)
-- Dumped by pg_dump version 16.3 (Debian 16.3-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: atualizarestoqueemmassa(integer[], integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.atualizarestoqueemmassa(IN produtoids integer[], IN quantidade integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    id INT;
BEGIN
    FOREACH id IN ARRAY produtoIds
    LOOP
        UPDATE Produtos
        SET Estoque = Estoque + quantidade
        WHERE ProdutoID = id;
    END LOOP;
END;
$$;


--
-- Name: atualizarprecoproduto(integer, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.atualizarprecoproduto(IN produtoid integer, IN novopreco numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Produtos
    SET Preco = novoPreco
    WHERE ProdutoID = produtoID;
END;
$$;


--
-- Name: calculardesconto(integer, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculardesconto(produtoidbusca integer, desconto double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$

DECLARE
	valorFinal DOUBLE PRECISION;
BEGIN
	SELECT preco INTO valorFinal from Produtos WHERE produtoid = produtoidBusca;
    
    valorFinal = valorFinal * (1 - desconto);
    
    RETURN valorFinal;
END;

$$;


--
-- Name: calcularfrete(numeric, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcularfrete(valortotal numeric, cidade character varying) RETURNS double precision
    LANGUAGE plpgsql
    AS $$

DECLARE
    valorFrete DOUBLE PRECISION;
BEGIN
    IF cidade = 'São Paulo' THEN
        valorFrete := valortotal * 0.05;
    ELSE
        valorFrete := valortotal * 0.10;
    END IF;
    
    RETURN valorFrete;
END;
$$;


--
-- Name: calcularidade(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcularidade(datanascimento date) RETURNS integer
    LANGUAGE plpgsql
    AS $$

BEGIN
	RETURN EXTRACT(YEAR from CURRENT_DATE) - EXTRACT(YEAR FROM datanascimento);
end;
$$;


--
-- Name: calcularpontos(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcularpontos(clienteidbusca integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
DECLARE
    pontosTotais DOUBLE PRECISION := 0;
    valorPedido RECORD;  -- 'RECORD' Usado para armazenar o resultado do SELECT
BEGIN

    FOR valorPedido IN SELECT ValorTotal FROM Pedidos WHERE ClienteID = clienteidBusca
    LOOP

        IF valorPedido.ValorTotal > 100 THEN
            pontosTotais := pontosTotais + 10;
        ELSE
            pontosTotais := pontosTotais + 5;
        END IF;
    END LOOP;
    
    RETURN pontosTotais;
END;
$$;


--
-- Name: excluircliente(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.excluircliente(IN clienteid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN

    DELETE FROM ItensPedido
    WHERE PedidoID IN (SELECT PedidoID FROM Pedidos WHERE ClienteID = clienteID);

    DELETE FROM Pedidos
    WHERE ClienteID = clienteID;

    DELETE FROM Clientes
    WHERE ClienteID = clienteID;
END;
$$;


--
-- Name: inserircliente(character varying, character varying, date, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.inserircliente(IN nome character varying, IN email character varying, IN datanascimento date, IN cidade character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Clientes (Nome, Email, DataNascimento, Cidade)
    VALUES (nome, email, dataNascimento, cidade);
END;
$$;


--
-- Name: inserirclientecomverificacao(character varying, character varying, date, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.inserirclientecomverificacao(IN nome character varying, IN email character varying, IN datanascimento date, IN cidade character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    emailExistente INT;
BEGIN
    SELECT COUNT(*) INTO emailExistente
    FROM Clientes
    WHERE Email = email;

    IF emailExistente > 0 THEN
        RAISE EXCEPTION 'O email % já está cadastrado.', email;
    ELSE
        INSERT INTO Clientes (Nome, Email, DataNascimento, Cidade)
        VALUES (nome, email, dataNascimento, cidade);
    END IF;
END;
$$;


--
-- Name: obternomecliente(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.obternomecliente(clienteidbusca integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE
	buscando VARCHAR;
BEGIN
	SELECT nome INTO buscando from clientes WHERE clienteid = clienteidBusca;
    
    RETURN buscando;
END;

$$;


--
-- Name: realizarpedido(integer, date, numeric, integer[], integer[], numeric[]); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.realizarpedido(IN clienteid integer, IN datapedido date, IN valortotal numeric, IN produtos integer[], IN quantidades integer[], IN precos numeric[])
    LANGUAGE plpgsql
    AS $$
DECLARE
    novoPedidoID INT;
    i INT;
BEGIN
    -- Inserir o novo pedido na tabela Pedidos
    INSERT INTO Pedidos (ClienteID, DataPedido, ValorTotal)
    VALUES (clienteID, dataPedido, valorTotal)
    RETURNING PedidoID INTO novoPedidoID;
    
    -- Inserir os itens do pedido na tabela ItensPedido
    FOR i IN 1..array_length(produtos, 1)
    LOOP
        INSERT INTO ItensPedido (PedidoID, ProdutoID, Quantidade, PrecoUnitario)
        VALUES (novoPedidoID, produtos[i], quantidades[i], precos[i]);
    END LOOP;
END;
$$;


--
-- Name: verificarestoque(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verificarestoque(produtoidbusca integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE
	buscando INT;
BEGIN
	SELECT estoque INTO buscando from Produtos WHERE produtoid = produtoidBusca;
    
    RETURN buscando;
END;

$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    clienteid integer NOT NULL,
    nome character varying(100),
    email character varying(100),
    datanascimento date,
    cidade character varying(50)
);


--
-- Name: clientes_clienteid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_clienteid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_clienteid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_clienteid_seq OWNED BY public.clientes.clienteid;


--
-- Name: demo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demo (
    id integer NOT NULL,
    name character varying(200) DEFAULT ''::character varying NOT NULL,
    hint text DEFAULT ''::text NOT NULL
);


--
-- Name: demo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.demo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: demo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.demo_id_seq OWNED BY public.demo.id;


--
-- Name: itenspedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itenspedido (
    itemid integer NOT NULL,
    pedidoid integer,
    produtoid integer,
    quantidade integer,
    precounitario numeric(10,2)
);


--
-- Name: itenspedido_itemid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.itenspedido_itemid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: itenspedido_itemid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.itenspedido_itemid_seq OWNED BY public.itenspedido.itemid;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos (
    pedidoid integer NOT NULL,
    clienteid integer,
    datapedido date,
    valortotal numeric(10,2)
);


--
-- Name: pedidos_pedidoid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedidos_pedidoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedidos_pedidoid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedidos_pedidoid_seq OWNED BY public.pedidos.pedidoid;


--
-- Name: produtos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produtos (
    produtoid integer NOT NULL,
    nomeproduto character varying(100),
    categoria character varying(50),
    preco numeric(10,2),
    estoque integer
);


--
-- Name: produtos_produtoid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produtos_produtoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produtos_produtoid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.produtos_produtoid_seq OWNED BY public.produtos.produtoid;


--
-- Name: clientes clienteid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN clienteid SET DEFAULT nextval('public.clientes_clienteid_seq'::regclass);


--
-- Name: demo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demo ALTER COLUMN id SET DEFAULT nextval('public.demo_id_seq'::regclass);


--
-- Name: itenspedido itemid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itenspedido ALTER COLUMN itemid SET DEFAULT nextval('public.itenspedido_itemid_seq'::regclass);


--
-- Name: pedidos pedidoid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN pedidoid SET DEFAULT nextval('public.pedidos_pedidoid_seq'::regclass);


--
-- Name: produtos produtoid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos ALTER COLUMN produtoid SET DEFAULT nextval('public.produtos_produtoid_seq'::regclass);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (clienteid);


--
-- Name: demo demo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demo
    ADD CONSTRAINT demo_pkey PRIMARY KEY (id);


--
-- Name: itenspedido itenspedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itenspedido
    ADD CONSTRAINT itenspedido_pkey PRIMARY KEY (itemid);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (pedidoid);


--
-- Name: produtos produtos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_pkey PRIMARY KEY (produtoid);


--
-- Name: itenspedido itenspedido_pedidoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itenspedido
    ADD CONSTRAINT itenspedido_pedidoid_fkey FOREIGN KEY (pedidoid) REFERENCES public.pedidos(pedidoid);


--
-- Name: itenspedido itenspedido_produtoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itenspedido
    ADD CONSTRAINT itenspedido_produtoid_fkey FOREIGN KEY (produtoid) REFERENCES public.produtos(produtoid);


--
-- Name: pedidos pedidos_clienteid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_clienteid_fkey FOREIGN KEY (clienteid) REFERENCES public.clientes(clienteid);


--
-- PostgreSQL database dump complete
--

