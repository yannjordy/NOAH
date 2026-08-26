import 'dart:math' show min;
import 'agent_base.dart';
import 'market_agent.dart';
import 'trading_agent.dart';
import 'risk_agent.dart';
import 'portfolio_agent.dart';
import 'macro_research_agent.dart';
import 'backtest_agent.dart';
import 'jordy_agent.dart';
import 'regime_agent.dart';
import 'onchain_agent.dart';
import 'liquidity_agent.dart';
import 'optimizer_agent.dart';
import 'attribution_agent.dart';
import '../models/blocks.dart';

class MainAgent extends BaseAgent {
  final MarketAgent _market = MarketAgent();
  final TradingAgent _trading = TradingAgent();
  final RiskAgent _risk = RiskAgent();
  final PortfolioAgent _portfolio = PortfolioAgent();
  final MacroResearchAgent _macro = MacroResearchAgent();
  final BacktestAgent _backtest = BacktestAgent();
  final JordyAgent _jordy = JordyAgent();
  final RegimeAgent _regime = RegimeAgent();
  final OnchainAgent _onchain = OnchainAgent();
  final LiquidityAgent _liquidity = LiquidityAgent();
  final OptimizerAgent _optimizer = OptimizerAgent();
  final AttributionAgent _attribution = AttributionAgent();

  AiThinker? _brain;
  void setBrain(AiThinker brain) => _brain = brain;
  bool get hasBrain => _brain != null;

  @override
  String get name => 'NOAH';

  @override
  AgentReport analyze(String symbol, AgentContext ctx) {
    final marketReport = _market.analyze(symbol, ctx);
    final riskReport = _risk.analyze(symbol, ctx);
    final tradingReport = _trading.analyze(symbol, ctx);
    final portfolioReport = _portfolio.analyze(symbol, ctx);
    final macroReport = _macro.analyze(symbol, ctx);
    final backtestReport = _backtest.analyze(symbol, ctx);
    final jordyReport = _jordy.analyze(symbol, ctx);
    final regimeReport = _regime.analyze(symbol, ctx);
    final onchainReport = _onchain.analyze(symbol, ctx);
    final liquidityReport = _liquidity.analyze(symbol, ctx);
    final optimizerReport = _optimizer.analyze(symbol, ctx);
    final attributionReport = _attribution.analyze(symbol, ctx);
    final consensus = _buildConsensus(marketReport, riskReport, symbol);

    return AgentReport(
      agentName: name,
      confidence: consensus['confidence'],
      summary: consensus['action'] as String,
      recommendation: consensus['action'],
      details: {
        'market': marketReport.details,
        'risk': riskReport.details,
        'trading': tradingReport.details,
        'portfolio': portfolioReport.details,
        'macro': macroReport.details,
        'backtest': backtestReport.details,
        'jordy': jordyReport.details,
        'regime': regimeReport.details,
        'onchain': onchainReport.details,
        'liquidity': liquidityReport.details,
        'optimizer': optimizerReport.details,
        'attribution': attributionReport.details,
        'consensus': consensus,
      },
    );
  }

  /// AI-powered full analysis: gathers data from all agents, then asks OpenCode brain for intelligent decision
  Future<AnalysisResult> fullAnalysisWithAI(String symbol, AgentContext ctx) async {
    // Step 1: Gather data from all agents (synchronous, fast)
    final marketReport = _market.analyze(symbol, ctx);
    final riskReport = _risk.analyze(symbol, ctx);
    final tradingReport = _trading.analyze(symbol, ctx);
    final portfolioReport = _portfolio.analyze(symbol, ctx);
    final macroReport = _macro.analyze(symbol, ctx);
    final backtestReport = _backtest.analyze(symbol, ctx);
    final jordyReport = _jordy.analyze(symbol, ctx);
    final regimeReport = _regime.analyze(symbol, ctx);
    final onchainReport = _onchain.analyze(symbol, ctx);
    final liquidityReport = _liquidity.analyze(symbol, ctx);
    final optimizerReport = _optimizer.analyze(symbol, ctx);
    final attributionReport = _attribution.analyze(symbol, ctx);

    // Step 2: Build context for OpenCode brain
    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;
    final rsi = marketReport.details['rsi'] as double?;
    final sma20 = marketReport.details['sma20'] as double?;
    final volRatio = marketReport.details['volRatio'] as double?;
    final riskScore = riskReport.details['riskScore'] as double? ?? 0;
    final circuitBreaker = riskReport.details['circuitBreaker'] as bool? ?? false;
    final exposurePct = riskReport.details['exposurePct'] as double? ?? 0;

    // Portfolio state
    final posValue = ctx.positions.fold(0.0, (s, p) {
      final c = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * c;
    });
    final totalCost = ctx.positions.fold(0.0, (s, p) => s + p.qty * p.entryPrice);
    final pnl = posValue - totalCost;
    final pnlPct = totalCost > 0 ? (pnl / totalCost * 100) : 0.0;

    // Positions detail
    final positionsDetail = ctx.positions.map((p) {
      final c = ctx.prices[p.symbol] ?? 0;
      final pp = p.pnlPct(c);
      return '- ${p.symbol}: ${p.qty.toStringAsFixed(4)} @ \$${p.entryPrice.toStringAsFixed(2)} → \$${c.toStringAsFixed(2)} (${pp >= 0 ? '+' : ''}${pp.toStringAsFixed(1)}%)';
    }).join('\n');

    // History
    final historyDetail = ctx.history.take(10).map((t) =>
      '- ${t.side.toUpperCase()} ${t.symbol}: ${t.qty.toStringAsFixed(4)} @ \$${t.price.toStringAsFixed(2)} (${t.time})'
    ).join('\n');

    // Step 3: Build comprehensive prompt for OpenCode
    final prompt = '''
Tu es le cerveau de NOAH, un trader IA expert. Analyse cette situation et décide.

## CONTEXTE MARCHÉ — $symbol
- Prix actuel: \$${price.toStringAsFixed(2)} (${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)
- RSI: ${rsi?.toStringAsFixed(1) ?? 'N/A'}
- SMA20: \$${sma20?.toStringAsFixed(2) ?? 'N/A'}
- Ratio volume: ${volRatio?.toStringAsFixed(2) ?? 'N/A'}x
- Tendance: ${sma20 != null && price > sma20 ? 'HAUSSIÈRE' : 'BAISSIÈRE'}

## AGENT MARCHÉ (Farida)
- Score: ${(marketReport.details['score'] as double? ?? 0.5).toStringAsFixed(2)} (0=vendeur, 1=acheteur)
- Support: \$${(marketReport.details['support'] as double? ?? 0).toStringAsFixed(2)}
- Résistance: \$${(marketReport.details['resistance'] as double? ?? 0).toStringAsFixed(2)}

## AGENT RISQUE (Henri)
- Score de risque: ${riskScore.toStringAsFixed(2)} (0=sûr, 1=dangereux)
- Circuit Breaker: ${circuitBreaker ? 'OUI ⛔' : 'NON ✅'}
- Exposition: ${(exposurePct * 100).toStringAsFixed(0)}%
- Drawdown journalier: ${((riskReport.details['dailyDrawdown'] as double? ?? 0) * 100).toStringAsFixed(1)}%

## PORTEFEUILLE
- Capital USDT: \$${ctx.usdtBalance.toStringAsFixed(2)}
- Valeur positions: \$${posValue.toStringAsFixed(2)}
- PnL total: \$${pnl.toStringAsFixed(2)} (${pnlPct >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%)
- Positions: ${ctx.positions.length}
$positionsDetail

## HISTORIQUE RÉCENT
$historyDetail

## INSTRUCTIONS
Réponds UNIQUEMENT en JSON avec cette structure exacte:
{
  "action": "BUY" | "SELL" | "HOLD",
  "confidence": 0.0 à 1.0,
  "reasoning": "explication courte de ta décision",
  "positionSizePct": pourcentage du capital à utiliser (ex: 15),
  "stopLoss": prix stop loss (optionnel),
  "takeProfit": prix take profit (optionnel)
}

Règles:
- Ne risque JAMAIS plus de 2% du capital sur un trade
- Si circuit breaker = OUI, FORCE action = "HOLD"
- Si risque > 0.5, sois très conservateur
- Priorise la protection du capital
- Un trade n'est justifié que si la confiance > 0.35
''';

    // Step 4: Ask OpenCode brain
    AnalysisResult result;
    try {
      final reply = await _brain!(prompt, systemContext: 'Tu es le cerveau décisionnel de NOAH Trading. Tu analyses les données de 12 agents et prends la décision finale intelligente. Réponds UNIQUEMENT en JSON.');
      result = _parseAIResponse(reply, symbol, ctx, marketReport, riskReport, tradingReport, portfolioReport, macroReport, backtestReport, jordyReport, regimeReport, onchainReport, liquidityReport, optimizerReport, attributionReport);
    } catch (e) {
      // Fallback to rule-based if AI fails
      result = fullAnalysis(symbol, ctx);
    }

    return result;
  }

  AnalysisResult _parseAIResponse(
    String reply,
    String symbol,
    AgentContext ctx,
    AgentReport marketReport,
    AgentReport riskReport,
    AgentReport tradingReport,
    AgentReport portfolioReport,
    AgentReport macroReport,
    AgentReport backtestReport,
    AgentReport jordyReport,
    AgentReport regimeReport,
    AgentReport onchainReport,
    AgentReport liquidityReport,
    AgentReport optimizerReport,
    AgentReport attributionReport,
  ) {
    // Try to parse JSON from reply
    String jsonStr = reply;
    // Extract JSON from markdown code blocks if present
    final jsonMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```').firstMatch(reply);
    if (jsonMatch != null) {
      jsonStr = jsonMatch.group(1)!;
    } else {
      // Try to find raw JSON
      final rawMatch = RegExp(r'\{[\s\S]*"action"[\s\S]*\}').firstMatch(reply);
      if (rawMatch != null) jsonStr = rawMatch.group(0)!;
    }

    String action = 'HOLD';
    double confidence = 0.0;
    String reasoning = '';
    double positionSizePct = 10;

    try {
      // Simple JSON parsing without dart:convert
      action = RegExp(r'"action"\s*:\s*"(\w+)"').firstMatch(jsonStr)?.group(1) ?? 'HOLD';
      confidence = double.tryParse(RegExp(r'"confidence"\s*:\s*([\d.]+)').firstMatch(jsonStr)?.group(1) ?? '0') ?? 0;
      reasoning = RegExp(r'"reasoning"\s*:\s*"([^"]*)"').firstMatch(jsonStr)?.group(1) ?? '';
      positionSizePct = double.tryParse(RegExp(r'"positionSizePct"\s*:\s*([\d.]+)').firstMatch(jsonStr)?.group(1) ?? '10') ?? 10;
    } catch (_) {
      // Parse failed, use fallback
    }

    // Validate action
    if (!['BUY', 'SELL', 'HOLD'].contains(action)) action = 'HOLD';

    // Apply risk overrides
    final circuitBreaker = riskReport.details['circuitBreaker'] as bool? ?? false;
    if (circuitBreaker) {
      action = 'HOLD';
      confidence = 0;
    }

    // Build consensus with AI decision
    final consensus = {
      'action': action,
      'confidence': confidence,
      'marketScore': marketReport.details['score'] as double? ?? 0.5,
      'riskScore': riskReport.details['riskScore'] as double? ?? 0,
      'circuitBreaker': circuitBreaker,
      'aiReasoning': reasoning,
      'aiPositionSizePct': positionSizePct,
    };

    final blocks = _buildBlocks(symbol, ctx, marketReport, riskReport, tradingReport, portfolioReport, macroReport, backtestReport, consensus);

    return AnalysisResult(
      blocks: blocks,
      narrative: reasoning,
      consensus: consensus,
      market: marketReport,
      risk: riskReport,
      trading: tradingReport,
      portfolio: portfolioReport,
      macro: macroReport,
      backtest: backtestReport,
      jordy: jordyReport,
      regime: regimeReport,
      onchain: onchainReport,
      liquidity: liquidityReport,
      optimizer: optimizerReport,
      attribution: attributionReport,
    );
  }

  AnalysisResult fullAnalysis(String symbol, AgentContext ctx) {
    final marketReport = _market.analyze(symbol, ctx);
    final riskReport = _risk.analyze(symbol, ctx);
    final tradingReport = _trading.analyze(symbol, ctx);
    final portfolioReport = _portfolio.analyze(symbol, ctx);
    final macroReport = _macro.analyze(symbol, ctx);
    final backtestReport = _backtest.analyze(symbol, ctx);
    final jordyReport = _jordy.analyze(symbol, ctx);
    final regimeReport = _regime.analyze(symbol, ctx);
    final onchainReport = _onchain.analyze(symbol, ctx);
    final liquidityReport = _liquidity.analyze(symbol, ctx);
    final optimizerReport = _optimizer.analyze(symbol, ctx);
    final attributionReport = _attribution.analyze(symbol, ctx);
    final consensus = _buildConsensus(marketReport, riskReport, symbol);
    final blocks = _buildBlocks(symbol, ctx, marketReport, riskReport, tradingReport, portfolioReport, macroReport, backtestReport, consensus);

    return AnalysisResult(
      blocks: blocks,
      narrative: '',
      consensus: consensus,
      market: marketReport,
      risk: riskReport,
      trading: tradingReport,
      portfolio: portfolioReport,
      macro: macroReport,
      backtest: backtestReport,
      jordy: jordyReport,
      regime: regimeReport,
      onchain: onchainReport,
      liquidity: liquidityReport,
      optimizer: optimizerReport,
      attribution: attributionReport,
    );
  }

  Map<String, dynamic> _buildConsensus(AgentReport market, AgentReport risk, String symbol) {
    final marketScore = market.details['score'] as double? ?? 0.5;
    final riskScore = risk.details['riskScore'] as double? ?? 0.0;
    final circuitBreaker = risk.details['circuitBreaker'] as bool? ?? false;

    double finalScore = marketScore;
    String finalAction;

    if (circuitBreaker) {
      finalAction = 'HOLD';
      finalScore = 0.0;
    } else if (riskScore > 0.6) {
      finalAction = 'HOLD';
      finalScore = min(finalScore, 0.3);
    } else if (riskScore > 0.3) {
      finalScore *= (1.0 - riskScore);
      if (marketScore > 0.52) finalAction = 'BUY';
      else if (marketScore < 0.48) finalAction = 'SELL';
      else finalAction = 'HOLD';
    } else {
      if (marketScore > 0.52) finalAction = 'BUY';
      else if (marketScore < 0.48) finalAction = 'SELL';
      else finalAction = 'HOLD';
    }

    final confidence = finalAction == 'HOLD'
        ? 0.0
        : (((finalScore - 0.5).abs() + 0.2) * 2 * (1.0 - riskScore * 0.3)).clamp(0.0, 1.0);

    return {
      'action': finalAction,
      'confidence': confidence,
      'marketScore': marketScore,
      'riskScore': riskScore,
      'circuitBreaker': circuitBreaker,
    };
  }

  List<MessageBlock> _buildBlocks(
    String symbol,
    AgentContext ctx,
    AgentReport market,
    AgentReport risk,
    AgentReport trading,
    AgentReport portfolio,
    AgentReport macro,
    AgentReport backtest,
    Map<String, dynamic> consensus,
  ) {
    final blocks = <MessageBlock>[];
    final price = ctx.prices[symbol] ?? 0;
    final pct = ctx.pcts[symbol] ?? 0;
    final action = consensus['action'] as String;
    final confidence = consensus['confidence'] as double;
    final circuitBreaker = consensus['circuitBreaker'] as bool;

    // 1. Signal Header
    blocks.add(MessageBlock.signalHeader(
      action: action,
      confidence: confidence,
      symbol: symbol,
      price: price,
      change: pct,
      period: '24h',
    ));

    // 2. Market Analysis
    blocks.add(MessageBlock.text('📊 Analyse Marché'));
    final closes = (market.details['closes'] as List<double>?) ?? [];
    if (closes.length >= 10) {
      blocks.add(MessageBlock.chartPreview(closes: closes, symbol: symbol));
    }

    // 3. Technical Factors
    final factors = <String, dynamic>{};
    if (market.details['rsi'] != null) factors['RSI'] = (market.details['rsi'] as double).toStringAsFixed(1);
    if (market.details['sma20'] != null) factors['SMA20'] = '\$${(market.details['sma20'] as double).toStringAsFixed(0)}';
    if (market.details['volRatio'] != null) factors['Volume'] = '${(market.details['volRatio'] as double).toStringAsFixed(2)}x';
    if (market.details['volatility'] != null) factors['Volatilité'] = '${((market.details['volatility'] as double) * 100).toStringAsFixed(1)}%';
    if (factors.isNotEmpty) {
      blocks.add(MessageBlock.factorGrid(factors));
    }

    // RSI commentary
    final rsi = market.details['rsi'] as double?;
    if (rsi != null) {
      if (rsi < 35) {
        blocks.add(MessageBlock.text('⚠ RSI en zone survendue (${rsi.toStringAsFixed(0)}) — potentiel rebond'));
      } else if (rsi > 65) {
        blocks.add(MessageBlock.text('⚠ RSI en zone surachat (${rsi.toStringAsFixed(0)}) — attention retournement'));
      }
    }

    // 4. Divider
    blocks.add(MessageBlock.divider());

    // 5. Risk Assessment
    blocks.add(MessageBlock.text('🛡 Gestion des Risques'));
    blocks.add(MessageBlock.riskGauge(
      riskScore: risk.details['riskScore'] as double? ?? 0,
      exposure: risk.details['exposurePct'] as double? ?? 0,
      dailyDrawdown: risk.details['dailyDrawdown'] as double? ?? 0,
      circuitBreaker: circuitBreaker,
      riskLevel: risk.details['riskLevel'] as String? ?? 'LOW',
    ));

    // 6. Divider
    blocks.add(MessageBlock.divider());

    // 7. Portfolio Summary
    blocks.add(MessageBlock.text('💼 Portefeuille'));
    final totalValue = ctx.usdtBalance + ctx.positions.fold(0.0, (s, p) {
      final c = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * c;
    });
    final posValue = ctx.positions.fold(0.0, (s, p) {
      final c = ctx.prices[p.symbol] ?? 0;
      return s + p.qty * c;
    });
    final totalCost = ctx.positions.fold(0.0, (s, p) => s + p.qty * p.entryPrice);
    final pnl = posValue - totalCost;
    final pnlPct = totalCost > 0 ? ((pnl / totalCost) * 100).toDouble() : 0.0;
    final usdtRatio = totalValue > 0 ? ((ctx.usdtBalance / totalValue) * 100).toDouble() : 100.0;

    blocks.add(MessageBlock.portfolioSummary(
      usdt: ctx.usdtBalance,
      posValue: posValue,
      pnl: pnl,
      pnlPct: pnlPct,
      positionCount: ctx.positions.length,
      totalValue: totalValue,
      usdtRatio: usdtRatio,
    ));

    // 8. Positions table
    if (ctx.positions.isNotEmpty) {
      blocks.add(MessageBlock.table(
        title: 'Positions ouvertes',
        headers: ['Symbole', 'Qté', 'Entrée', 'PnL'],
        rows: ctx.positions.map((pos) {
          final c = ctx.prices[pos.symbol] ?? 0;
          final pp = pos.pnlPct(c);
          return [
            pos.symbol,
            pos.qty.toStringAsFixed(4),
            '\$${pos.entryPrice.toStringAsFixed(2)}',
            '${pp >= 0 ? '+' : ''}${pp.toStringAsFixed(1)}%',
          ];
        }).toList(),
      ));
    }

    // 9. Macro Research
    final macroDetail = macro.details;
    final webCount = macroDetail['webResults'] as int? ?? 0;
    final fg = macroDetail['fearGreed'] as int? ?? 50;
    if (webCount > 0 || fg != 50) {
      blocks.add(MessageBlock.divider());
      blocks.add(MessageBlock.text('🌐 Recherche Web & Macro'));
      blocks.add(MessageBlock.text(
        'Emma a trouvé $webCount résultats web. Fear & Greed: $fg/100. ${macro.summary}',
      ));
    }

    // 10. Backtest
    final btDetail = backtest.details;
    if (btDetail['totalCandles'] is int && (btDetail['totalCandles'] as int) > 0) {
      blocks.add(MessageBlock.divider());
      blocks.add(MessageBlock.text('📈 Backtest (Junior)'));
      blocks.add(MessageBlock.text(
        'Train: ${btDetail['trainTrades']} trades, WR ${((btDetail['trainWinRate'] as double) * 100).toStringAsFixed(0)}%, '
        'Sharpe ${(btDetail['trainSharpe'] as double).toStringAsFixed(2)} | '
        'Test: ${btDetail['testTrades']} trades, WR ${((btDetail['testWinRate'] as double) * 100).toStringAsFixed(0)}%, '
        'Sharpe ${(btDetail['testSharpe'] as double).toStringAsFixed(2)}'
        '${btDetail['overfit'] == true ? ' ⚠ Overfit' : ''}',
      ));
    }

    // 11. Recommendation
    blocks.add(MessageBlock.divider());
    blocks.add(MessageBlock.text('🎯 Recommandation'));

    if (circuitBreaker) {
      blocks.add(MessageBlock.text('⛔ Circuit Breaker activé — Trading suspendu. Réévaluation nécessaire.'));
    } else {
      if (action == 'BUY') {
        final support = market.details['support'] as double? ?? price * 0.97;
        final resistance = market.details['resistance'] as double? ?? price * 1.03;
        blocks.add(MessageBlock.table(
          title: 'Niveaux clés',
          headers: ['Indicateur', 'Valeur'],
          rows: [
            ['Entrée', '\$${price.toStringAsFixed(2)}'],
            ['Objectif', '\$${resistance.toStringAsFixed(2)} (+${((resistance / price - 1) * 100).toStringAsFixed(1)}%)'],
            ['Stop Loss', '\$${support.toStringAsFixed(2)} (${((support / price - 1) * 100).toStringAsFixed(1)}%)'],
            ['R/R Ratio', '${((resistance - price) / ((price - support).clamp(0.01, double.infinity))).toStringAsFixed(2)}'],
          ],
        ));
      } else if (action == 'SELL') {
        final support = market.details['support'] as double? ?? price * 0.97;
        final resistance = market.details['resistance'] as double? ?? price * 1.03;
        blocks.add(MessageBlock.table(
          title: 'Niveaux clés',
          headers: ['Indicateur', 'Valeur'],
          rows: [
            ['Entrée', '\$${price.toStringAsFixed(2)}'],
            ['Objectif', '\$${support.toStringAsFixed(2)} (${((support / price - 1) * 100).toStringAsFixed(1)}%)'],
            ['Stop Loss', '\$${resistance.toStringAsFixed(2)} (+${((resistance / price - 1) * 100).toStringAsFixed(1)}%)'],
          ],
        ));
      } else {
        final riskScore = risk.details['riskScore'] as double? ?? 0;
        blocks.add(MessageBlock.text(
          riskScore > 0.2
              ? '⚠ Conditions de marché incertaines. Surveillance recommandée.'
              : '✅ Marché neutre. Aucun signal clair. Attendre une meilleure configuration.',
        ));
      }
    }

    blocks.add(MessageBlock.divider());
    blocks.add(MessageBlock.text('🔍 Raisonnement: Décision basée sur tous les agents — Farida, Henri, Alexendra, Dylan, Emmilienne, Junior, Jordy, Régime, Chaîne, Liquidité, Optimiseur, Attribution.'));
    blocks.add(MessageBlock.text('⚠ Trading fictif — environnement démo.'));

    return blocks;
  }
}

class AnalysisResult {
  final List<MessageBlock> blocks;
  final String narrative;
  final Map<String, dynamic> consensus;
  final AgentReport market;
  final AgentReport risk;
  final AgentReport trading;
  final AgentReport portfolio;
  final AgentReport macro;
  final AgentReport backtest;
  final AgentReport jordy;
  final AgentReport regime;
  final AgentReport onchain;
  final AgentReport liquidity;
  final AgentReport optimizer;
  final AgentReport attribution;

  AnalysisResult({
    required this.blocks,
    required this.narrative,
    required this.consensus,
    required this.market,
    required this.risk,
    required this.trading,
    required this.portfolio,
    required this.macro,
    required this.backtest,
    AgentReport? jordy,
    AgentReport? regime,
    AgentReport? onchain,
    AgentReport? liquidity,
    AgentReport? optimizer,
    AgentReport? attribution,
  }) : jordy = jordy ?? AgentReport(
         agentName: 'Jordy', confidence: 0, summary: '', details: {}),
       regime = regime ?? AgentReport(
         agentName: 'Régime', confidence: 0, summary: '', details: {}),
       onchain = onchain ?? AgentReport(
         agentName: 'Chaîne', confidence: 0, summary: '', details: {}),
       liquidity = liquidity ?? AgentReport(
         agentName: 'Liquidité', confidence: 0, summary: '', details: {}),
       optimizer = optimizer ?? AgentReport(
         agentName: 'Optimiseur', confidence: 0, summary: '', details: {}),
       attribution = attribution ?? AgentReport(
         agentName: 'Attribution', confidence: 0, summary: '', details: {});
}
