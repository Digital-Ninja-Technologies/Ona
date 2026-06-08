import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  Modal,
  FlatList,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  ArrowLeft,
  ArrowLeftRight,
  RefreshCw,
  ChevronDown,
  Search,
  X,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { InstrumentSans_500Medium } from "@expo-google-fonts/instrument-sans";
import { useTheme } from "@/utils/theme/useTheme";

// Currency names mapping
const currencyNames = {
  USD: "US Dollar",
  EUR: "Euro",
  GBP: "British Pound",
  JPY: "Japanese Yen",
  AUD: "Australian Dollar",
  CAD: "Canadian Dollar",
  CHF: "Swiss Franc",
  CNY: "Chinese Yuan",
  INR: "Indian Rupee",
  MXN: "Mexican Peso",
  BRL: "Brazilian Real",
  ZAR: "South African Rand",
  RUB: "Russian Ruble",
  KRW: "South Korean Won",
  SGD: "Singapore Dollar",
  HKD: "Hong Kong Dollar",
  NOK: "Norwegian Krone",
  SEK: "Swedish Krona",
  DKK: "Danish Krone",
  NZD: "New Zealand Dollar",
  TRY: "Turkish Lira",
  PLN: "Polish Zloty",
  THB: "Thai Baht",
  MYR: "Malaysian Ringgit",
  IDR: "Indonesian Rupiah",
  PHP: "Philippine Peso",
  AED: "UAE Dirham",
  SAR: "Saudi Riyal",
  ILS: "Israeli Shekel",
  CZK: "Czech Koruna",
  HUF: "Hungarian Forint",
  RON: "Romanian Leu",
  CLP: "Chilean Peso",
  ARS: "Argentine Peso",
  COP: "Colombian Peso",
  PEN: "Peruvian Sol",
  VND: "Vietnamese Dong",
  EGP: "Egyptian Pound",
  NGN: "Nigerian Naira",
  KES: "Kenyan Shilling",
  PKR: "Pakistani Rupee",
  BDT: "Bangladeshi Taka",
  UAH: "Ukrainian Hryvnia",
};

// Currency symbols
const currencySymbols = {
  USD: "$",
  EUR: "€",
  GBP: "£",
  JPY: "¥",
  AUD: "A$",
  CAD: "C$",
  CHF: "Fr",
  CNY: "¥",
  INR: "₹",
  MXN: "$",
  BRL: "R$",
  ZAR: "R",
  RUB: "₽",
  KRW: "₩",
  SGD: "S$",
  HKD: "HK$",
  NOK: "kr",
  SEK: "kr",
  DKK: "kr",
  NZD: "NZ$",
  TRY: "₺",
  PLN: "zł",
  THB: "฿",
  MYR: "RM",
  IDR: "Rp",
  PHP: "₱",
  AED: "د.إ",
  SAR: "﷼",
  ILS: "₪",
  CZK: "Kč",
  HUF: "Ft",
  RON: "lei",
  CLP: "$",
  ARS: "$",
  COP: "$",
  PEN: "S/",
  VND: "₫",
  EGP: "E£",
  NGN: "₦",
  KES: "KSh",
  PKR: "₨",
  BDT: "৳",
  UAH: "₴",
};

const popularCurrencyCodes = [
  "USD",
  "EUR",
  "GBP",
  "JPY",
  "AUD",
  "CAD",
  "CHF",
  "CNY",
  "INR",
  "MXN",
  "BRL",
  "ZAR",
];

export default function CurrencyConverterScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [amount, setAmount] = useState("100");
  const [fromCurrency, setFromCurrency] = useState("USD");
  const [toCurrency, setToCurrency] = useState("EUR");
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [rates, setRates] = useState({});
  const [allCurrencies, setAllCurrencies] = useState([]);
  const [showFromPicker, setShowFromPicker] = useState(false);
  const [showToPicker, setShowToPicker] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
    InstrumentSans_500Medium,
  });

  useEffect(() => {
    fetchRates();
  }, []);

  useEffect(() => {
    if (amount && fromCurrency && toCurrency) {
      convertCurrency();
    }
  }, [amount, fromCurrency, toCurrency, rates]);

  const fetchRates = async () => {
    try {
      setLoading(true);
      const response = await fetch(
        "https://api.exchangerate-api.com/v4/latest/USD",
      );
      const data = await response.json();
      setRates(data.rates);

      // Create array of all currencies
      const currencies = Object.keys(data.rates)
        .map((code) => ({
          code,
          name: currencyNames[code] || code,
          symbol: currencySymbols[code] || code,
          rate: data.rates[code],
        }))
        .sort((a, b) => a.code.localeCompare(b.code));

      setAllCurrencies(currencies);
    } catch (error) {
      console.error("Error fetching rates:", error);
    } finally {
      setLoading(false);
    }
  };

  const convertCurrency = () => {
    if (!amount || !rates[fromCurrency] || !rates[toCurrency]) {
      setResult(null);
      return;
    }

    const amountNum = parseFloat(amount);
    if (isNaN(amountNum)) {
      setResult(null);
      return;
    }

    // Convert to USD first, then to target currency
    const inUSD = amountNum / rates[fromCurrency];
    const converted = inUSD * rates[toCurrency];
    setResult(converted.toFixed(2));
  };

  const swapCurrencies = () => {
    setFromCurrency(toCurrency);
    setToCurrency(fromCurrency);
  };

  const getCurrencyName = (code) => {
    return currencyNames[code] || code;
  };

  const getCurrencySymbol = (code) => {
    return currencySymbols[code] || code;
  };

  const getFilteredCurrencies = () => {
    if (!searchQuery.trim()) return allCurrencies;

    const query = searchQuery.toLowerCase();
    return allCurrencies.filter(
      (currency) =>
        currency.code.toLowerCase().includes(query) ||
        currency.name.toLowerCase().includes(query),
    );
  };

  const CurrencyPickerModal = ({
    visible,
    onClose,
    onSelect,
    currentCurrency,
  }) => {
    const filteredCurrencies = getFilteredCurrencies();

    return (
      <Modal
        visible={visible}
        animationType="slide"
        transparent={true}
        onRequestClose={onClose}
      >
        <View style={styles.modalOverlay}>
          <View
            style={[
              styles.modalContainer,
              { paddingBottom: insets.bottom + 20 },
            ]}
          >
            {/* Modal Header */}
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Select Currency</Text>
              <TouchableOpacity
                onPress={onClose}
                style={styles.modalCloseButton}
              >
                <X size={24} color={theme.icon} />
              </TouchableOpacity>
            </View>

            {/* Search Bar */}
            <View style={styles.modalSearchContainer}>
              <Search size={20} color={theme.searchPlaceholder} />
              <TextInput
                style={styles.modalSearchInput}
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search currency..."
                placeholderTextColor={theme.searchPlaceholder}
              />
              {searchQuery.length > 0 && (
                <TouchableOpacity onPress={() => setSearchQuery("")}>
                  <X size={18} color={theme.textSecondary} />
                </TouchableOpacity>
              )}
            </View>

            {/* Currency List */}
            <FlatList
              data={filteredCurrencies}
              keyExtractor={(item) => item.code}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[
                    styles.currencyItem,
                    item.code === currentCurrency &&
                      styles.currencyItemSelected,
                  ]}
                  onPress={() => {
                    onSelect(item.code);
                    onClose();
                    setSearchQuery("");
                  }}
                >
                  <View style={styles.currencyItemLeft}>
                    <Text style={styles.currencyItemCode}>{item.code}</Text>
                    <Text style={styles.currencyItemName}>{item.name}</Text>
                  </View>
                  <Text style={styles.currencyItemRate}>
                    {item.rate.toFixed(4)}
                  </Text>
                </TouchableOpacity>
              )}
            />
          </View>
        </View>
      </Modal>
    );
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    backButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 12,
    },
    headerTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: 24,
      paddingTop: 32,
    },
    converterCard: {
      backgroundColor: theme.surface,
      borderRadius: 24,
      padding: 24,
      marginBottom: 24,
      borderWidth: 1,
      borderColor: theme.border,
    },
    label: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 8,
    },
    amountInput: {
      backgroundColor: theme.background,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: 16,
      fontFamily: "Nunito_600SemiBold",
      fontSize: 32,
      color: theme.text,
      marginBottom: 20,
      borderWidth: 1,
      borderColor: theme.border,
    },
    currencySelector: {
      backgroundColor: theme.background,
      borderRadius: 16,
      padding: 16,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
    },
    currencyRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
    },
    currencyLeft: {
      flex: 1,
    },
    currencyCode: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 18,
      color: theme.text,
    },
    currencyName: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
      marginTop: 2,
    },
    swapButton: {
      alignSelf: "center",
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: "#FF6B9D",
      justifyContent: "center",
      alignItems: "center",
      marginVertical: 8,
    },
    resultContainer: {
      backgroundColor: "#FF6B9D",
      borderRadius: 20,
      padding: 24,
      marginBottom: 24,
    },
    resultLabel: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: "#1A1A1A",
      marginBottom: 8,
    },
    resultAmount: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 40,
      color: "#1A1A1A",
    },
    resultSubtext: {
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: "#1A1A1A",
      marginTop: 8,
      opacity: 0.8,
    },
    refreshButton: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 16,
      borderWidth: 1,
      borderColor: theme.border,
      marginBottom: 24,
    },
    refreshButtonText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 15,
      color: theme.text,
      marginLeft: 8,
    },
    popularGrid: {
      marginTop: 8,
    },
    popularTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
      marginBottom: 16,
    },
    currencyChip: {
      backgroundColor: theme.surface,
      borderRadius: 12,
      padding: 12,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
    },
    currencyChipRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
    },
    chipCode: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 15,
      color: theme.text,
    },
    chipRate: {
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: theme.textSecondary,
    },
    modalOverlay: {
      flex: 1,
      backgroundColor: "rgba(0, 0, 0, 0.5)",
      justifyContent: "flex-end",
    },
    modalContainer: {
      backgroundColor: theme.background,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      maxHeight: "85%",
      paddingTop: 20,
    },
    modalHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingHorizontal: 24,
      paddingBottom: 16,
    },
    modalTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 22,
      color: theme.text,
    },
    modalCloseButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
    },
    modalSearchContainer: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.searchBackground,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: 12,
      marginHorizontal: 24,
      marginBottom: 16,
    },
    modalSearchInput: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.text,
      marginLeft: 10,
    },
    currencyItem: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingVertical: 16,
      paddingHorizontal: 24,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    currencyItemSelected: {
      backgroundColor: theme.surface,
    },
    currencyItemLeft: {
      flex: 1,
    },
    currencyItemCode: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
      marginBottom: 2,
    },
    currencyItemName: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
    },
    currencyItemRate: {
      fontFamily: "Nunito_500Medium",
      fontSize: 14,
      color: theme.textSecondary,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Currency Converter</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Converter Card */}
        <View style={styles.converterCard}>
          <Text style={styles.label}>Amount</Text>
          <TextInput
            style={styles.amountInput}
            value={amount}
            onChangeText={setAmount}
            keyboardType="decimal-pad"
            placeholder="0.00"
            placeholderTextColor={theme.searchPlaceholder}
          />

          <Text style={styles.label}>From</Text>
          <TouchableOpacity
            style={styles.currencySelector}
            onPress={() => setShowFromPicker(true)}
          >
            <View style={styles.currencyRow}>
              <View style={styles.currencyLeft}>
                <Text style={styles.currencyCode}>{fromCurrency}</Text>
                <Text style={styles.currencyName}>
                  {getCurrencyName(fromCurrency)}
                </Text>
              </View>
              <ChevronDown size={24} color={theme.icon} />
            </View>
          </TouchableOpacity>

          <TouchableOpacity style={styles.swapButton} onPress={swapCurrencies}>
            <ArrowLeftRight size={24} color="#1A1A1A" />
          </TouchableOpacity>

          <Text style={styles.label}>To</Text>
          <TouchableOpacity
            style={styles.currencySelector}
            onPress={() => setShowToPicker(true)}
          >
            <View style={styles.currencyRow}>
              <View style={styles.currencyLeft}>
                <Text style={styles.currencyCode}>{toCurrency}</Text>
                <Text style={styles.currencyName}>
                  {getCurrencyName(toCurrency)}
                </Text>
              </View>
              <ChevronDown size={24} color={theme.icon} />
            </View>
          </TouchableOpacity>
        </View>

        {/* Result */}
        {result && (
          <View style={styles.resultContainer}>
            <Text style={styles.resultLabel}>Converted Amount</Text>
            <Text style={styles.resultAmount}>
              {getCurrencySymbol(toCurrency)}
              {result}
            </Text>
            <Text style={styles.resultSubtext}>
              1 {fromCurrency} ={" "}
              {(rates[toCurrency] / rates[fromCurrency]).toFixed(4)}{" "}
              {toCurrency}
            </Text>
          </View>
        )}

        {/* Refresh Rates */}
        <TouchableOpacity
          style={styles.refreshButton}
          onPress={fetchRates}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={theme.text} />
          ) : (
            <>
              <RefreshCw size={20} color={theme.icon} />
              <Text style={styles.refreshButtonText}>Refresh Rates</Text>
            </>
          )}
        </TouchableOpacity>

        {/* Popular Currencies */}
        <View style={styles.popularGrid}>
          <Text style={styles.popularTitle}>Popular Currencies</Text>
          {popularCurrencyCodes.map((code) => (
            <View key={code} style={styles.currencyChip}>
              <View style={styles.currencyChipRow}>
                <Text style={styles.chipCode}>
                  {getCurrencySymbol(code)} {code}
                </Text>
                {rates[code] && (
                  <Text style={styles.chipRate}>
                    1 USD = {rates[code].toFixed(4)} {code}
                  </Text>
                )}
              </View>
            </View>
          ))}
        </View>
      </ScrollView>

      {/* Currency Picker Modals */}
      <CurrencyPickerModal
        visible={showFromPicker}
        onClose={() => setShowFromPicker(false)}
        onSelect={setFromCurrency}
        currentCurrency={fromCurrency}
      />

      <CurrencyPickerModal
        visible={showToPicker}
        onClose={() => setShowToPicker(false)}
        onSelect={setToCurrency}
        currentCurrency={toCurrency}
      />
    </View>
  );
}
