import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink('https://beta.pokeapi.co/graphql/v1beta');

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  const MyApp({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: const CacheProvider(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPokemonId = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GraphQL PokeAPI Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Query(
              options: QueryOptions(
                document: gql(r'''
                  query GetAllPokemon {
                    pokemon_v2_pokemon {
                      id
                      name
                    }
                  }
                '''),
              ),
              builder: (QueryResult result, {fetchMore, refetch}) {
                if (result.hasException) {
                  return Text(result.exception.toString());
                }

                if (result.isLoading) {
                  return const CircularProgressIndicator();
                }

                final List pokemons = result.data?['pokemon_v2_pokemon'];

                return DropdownButton<int>(
                  value: _selectedPokemonId,
                  items: pokemons.map<DropdownMenuItem<int>>((pokemon) {
                    return DropdownMenuItem<int>(
                      value: pokemon['id'],
                      child: Text(pokemon['name']),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedPokemonId = newValue!;
                    });
                  },
                );
              },
            ),
            Expanded(
              child: Query(
                options: QueryOptions(
                  document: gql(r'''
                    query GetPokemon($id: Int!) {
                      pokemon_v2_pokemon_by_pk(id: $id) {
                        id
                        name
                        height
                        weight
                        pokemon_v2_pokemonsprites {
                          sprites
                        }
                      }
                    }
                  '''),
                  variables: {'id': _selectedPokemonId},
                ),
                builder: (QueryResult result, {fetchMore, refetch}) {
                  if (result.hasException) {
                    return Text(result.exception.toString());
                  }

                  if (result.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  final pokemon = result.data?['pokemon_v2_pokemon_by_pk'];

                  if (pokemon == null) {
                    return const Text('No Pokémon found');
                  }

                  final sprites = pokemon['pokemon_v2_pokemonsprites'][0]
                      ['sprites'] as Map<String, dynamic>;
                  final spriteUrl =
                      sprites['other']['official-artwork']['front_default'];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (spriteUrl != null) Image.network(spriteUrl),
                      Text('Name: ${pokemon['name']}'),
                      Text('Height: ${pokemon['height']}'),
                      Text('Weight: ${pokemon['weight']}'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
