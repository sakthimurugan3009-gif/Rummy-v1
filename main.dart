import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const RummyApp());

class CardModel {
  final String suit, rank;
  CardModel(this.suit, this.rank);
  int get value => ['J','Q','K','A'].contains(rank) ? 10 : int.parse(rank);
  @override String toString() => '$rank$suit';
}

class RummyApp extends StatelessWidget {
  const RummyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Rummy V1',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const GamePage(),
  );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final rng = Random();
  final List<CardModel> deck = [];
  final List<CardModel> hand = [];
  final List<CardModel> discard = [];
  int seconds = 35;
  Timer? timer;
  bool running = false;
  String status = 'Your turn — pick a card, then discard one.';
  final players = {'You': 0, 'Player 2': 42, 'Player 3': 67, 'Player 4': 18};

  @override void initState() { super.initState(); newGame(); }

  void newGame() {
    timer?.cancel();
    deck.clear(); hand.clear(); discard.clear();
    for (final s in ['♠','♥','♦','♣']) {
      for (final r in ['2','3','4','5','6','7','8','9','10','J','Q','K','A']) {
        deck.add(CardModel(s,r));
      }
    }
    deck.shuffle(rng);
    for (int i=0;i<13;i++) hand.add(deck.removeLast());
    discard.add(deck.removeLast());
    seconds=35; running=true; status='Your turn — pick a card, then discard one.';
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    timer?.cancel();
    timer=Timer.periodic(const Duration(seconds:1),(t){
      if (!mounted) return;
      setState(() {
        if (seconds>0) seconds--;
        if (seconds==0) {
          t.cancel();
          if (hand.isNotEmpty) {
            final c=hand.removeLast();
            discard.add(c);
            status='Time up — auto-discarded $c. Next turn.';
            players['You']=_score();
          }
          running=false;
        } else if (seconds<=5) {
          status='Hurry! $seconds seconds left.';
        }
      });
    });
  }

  int _score() => hand.fold(0,(a,c)=>a+c.value);

  void pick() {
    if (!running || deck.isEmpty) return;
    setState(() {
      hand.add(deck.removeLast());
      status='Card picked. Choose a card to discard.';
    });
  }

  void discardCard(int i) {
    if (!running || i<0 || i>=hand.length) return;
    setState(() {
      final c=hand.removeAt(i);
      discard.add(c);
      players['You']=_score();
      status='You discarded $c.';
      if (hand.length==13) status='Discarded $c. Your turn continues.';
    });
  }

  void declare() {
    setState(() {
      final points=_score();
      if (points<=80) status='Declare checked. Score: $points points.';
      else status='Invalid/unfinished declare. Arrange valid runs and sets first.';
    });
  }

  @override void dispose(){ timer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rummy V1'),
        actions:[IconButton(onPressed:newGame,icon:const Icon(Icons.refresh))],
      ),
      body: SafeArea(child: Column(children:[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children:[
            Expanded(child: Text(status,style:const TextStyle(fontWeight:FontWeight.w600))),
            Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
              decoration:BoxDecoration(borderRadius:BorderRadius.circular(12),color:seconds<=5?Colors.red.shade100:Colors.indigo.shade50),
              child:Text('$seconds s',style:const TextStyle(fontWeight:FontWeight.bold))),
          ]),
        ),
        SizedBox(height:90,child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
          _pile('Draw',deck.length,Icons.style,pick),
          _pile('Discard',discard.length,Icons.delete,()=>setState((){})),
        ])),
        const Divider(),
        Expanded(child:Row(children:[
          Expanded(child:Padding(padding:const EdgeInsets.all(8),child:GridView.builder(
            itemCount:hand.length,itemBuilder:(c,i)=>GestureDetector(
              onTap:()=>discardCard(i),
              child:Card(child:Center(child:Text('${hand[i]}',style:TextStyle(fontSize:20,color:(hand[i].suit=='♥'||hand[i].suit=='♦')?Colors.red:Colors.black))))
            ),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,childAspectRatio:.72),
          ))),
          SizedBox(width:125,child:Card(child:Padding(padding:const EdgeInsets.all(8),child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('Players',style:TextStyle(fontWeight:FontWeight.bold)),
              const SizedBox(height:8),
              ...players.entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:7),child:Text('${e.key}\n${e.value} pts',style:const TextStyle(fontSize:12)))),
              const Divider(),
              const Text('Discarded',style:TextStyle(fontWeight:FontWeight.bold)),
              Expanded(child:ListView.builder(reverse:true,itemCount:min(discard.length,12),itemBuilder:(c,i)=>Text('${discard[discard.length-1-i]}',style:const TextStyle(fontSize:12)))),
            ])))),
        ])),
        Padding(padding:const EdgeInsets.all(8),child:Row(children:[
          Expanded(child:OutlinedButton(onPressed:running?declare:null,child:const Text('DECLARE'))),
          const SizedBox(width:8),
          Expanded(child:FilledButton(onPressed:running?pick:null,child:const Text('PICK'))),
        ])),
        const Padding(padding:EdgeInsets.only(bottom:8),child:Text('Points-only prototype • No real money')),
      ])),
    );
  }

  Widget _pile(String label,int count,IconData icon,VoidCallback onTap)=>InkWell(
    onTap:onTap,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,size:34),Text(label),Text('$count cards',style:const TextStyle(fontSize:12))
    ]));
}
