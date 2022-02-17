﻿#Область ПрограммныйИнтерфейс

// Определяет необходимость обработки расширения. Необходимость возникает, когда осуществляется прыжок на или через указанную версию. 
//
// Параметры:
//  Обновления - Соответствие - см. функцию ПолучитьОбновления(). Эта переменная передается в событие
//    <А1Э_ПриОбновленииРасширений> первым параметром.
//  ИмяРасширения - Строка - 
//  Версия - Строка - Важно - сейчас сравнение выполняется через сравнение строк. 
// 
// Возвращаемое значение:
//   - Булево.
//
Функция НужноОбработать(Обновления, ИмяРасширения, Версия) Экспорт 
	ДанныеРасширения = Обновления[ИмяРасширения];
	Если ДанныеРасширения = Неопределено Тогда Возврат Ложь; КонецЕсли; //Версия не изменялась.
	Если НЕ ЗначениеЗаполнено(ДанныеРасширения.Ссылка) Тогда Возврат Ложь; КонецЕсли;
	Возврат ДанныеРасширения.СтараяВерсия < Версия И ДанныеРасширения.Версия >= Версия; 
КонецФункции

#Если НЕ Клиент Тогда
	
	// Возвращает признак наличия устаревших расширений (которые были изменены разработчиком после начала сеанса пользователя)
	// 
	// Возвращаемое значение:
	//   - Булево
	//
	Функция Устарели() Экспорт
		УстановитьПривилегированныйРежим(Истина);
		
		Возврат Ложь;	
//		Обновления = ПолучитьОбновления(ИсточникРасширенийКонфигурации.СеансАктивные);
//		Возврат Обновления.Количество() <> 0;
	КонецФункции
	
#КонецЕсли

#КонецОбласти

#Область Механизм

Функция НастройкиМеханизма() Экспорт
	Настройки = А1Э_Механизмы.НовыйНастройкиМеханизма();
	
	Настройки.Обработчики.Вставить("ПередНачаломРаботыСистемыВызовСервера", Истина);
	
	Настройки.ПорядокВыполнения = -10000;
	
	Возврат Настройки;
КонецФункции 

#Если НЕ Клиент Тогда
	
	Функция ПередНачаломРаботыСистемыВызовСервера(Отказ, ДанныеСервера) Экспорт 
		ЗафиксироватьОбновлениеРасширений(Отказ);
	КонецФункции
	
	Функция ЗафиксироватьОбновлениеРасширений(Отказ) 
		Если НЕ ПравоДоступа("Администрирование", Метаданные) Тогда Возврат Неопределено КонецЕсли;
		
		УстановитьПривилегированныйРежим(Истина);
		Обновления = ПолучитьОбновления();
		Если Обновления.Количество() = 0 Тогда Возврат Неопределено; КонецЕсли;
		
		Попытка
			А1Э_Механизмы.ВыполнитьМеханизмыОбработчика("А1Э_ПриОбновленииРасширений", Обновления);
		Исключение
			ОписаниеОшибки = ОписаниеОшибки();
			А1Э_Служебный.СлужебноеИсключение("Ошибка при выполнении обработчиков обновления - " + ОписаниеОшибки);
		КонецПопытки;
		
		ЗафиксироватьИзменения(Обновления);

	КонецФункции
	
	Функция ПолучитьОбновления(Знач ИсточникРасширений = Неопределено) Экспорт
		Если ИсточникРасширений = Неопределено Тогда ИсточникРасширений = ИсточникРасширенийКонфигурации.БазаДанных КонецЕсли;
		
		Результат = Новый Соответствие;		
		
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Расширения.Ссылка КАК Ссылка,
		|	Расширения.Наименование КАК Имя,
		|	Расширения.Версия КАК СтараяВерсия,
		|	Расширения.ХешСумма КАК СтараяХешСумма
		|ИЗ
		|	Справочник.А1Обновление_Расширения КАК Расширения";
		Выборка = Запрос.Выполнить().Выбрать();
		ДанныеРасширений = Новый Соответствие;
		Пока Выборка.Следующий() Цикл
			ДанныеРасширения = НовыйДанныеРасширения();
			ЗаполнитьЗначенияСвойств(ДанныеРасширения, Выборка);
			ДанныеРасширений.Вставить(Выборка.Имя, ДанныеРасширения);
		КонецЦикла;
		
		Расширения = РасширенияКонфигурации.Получить(, ИсточникРасширений);
		Для Каждого Расширение Из Расширения Цикл
			ДанныеРасширения = ДанныеРасширений[Расширение.Имя];
			Если ДанныеРасширения = Неопределено Тогда //Новое расширение
				ДанныеРасширения = НовыйДанныеРасширения();
				ЗаполнитьЗначенияСвойств(ДанныеРасширения, Расширение);
				Результат.Вставить(ДанныеРасширения.Имя, ДанныеРасширения);
				Продолжить;
			КонецЕсли;
			ДанныеРасширения.Существует = Истина;
			ДанныеРасширения.Версия = Расширение.Версия;
			ДанныеРасширения.ХешСумма = Строка(Расширение.ХешСумма);
			Если ДанныеРасширения.Версия <> ДанныеРасширения.СтараяВерсия Или ДанныеРасширения.ХешСумма <> ДанныеРасширения.СтараяХешСумма Тогда //Обновленное расширение
				Результат.Вставить(ДанныеРасширения.Имя, ДанныеРасширения);
			КонецЕсли;
		КонецЦикла;
		Для Каждого Пара Из ДанныеРасширений Цикл
			Если Пара.Значение.Существует = Неопределено Тогда //Удаленное расширение.
				Пара.Значение.Существует = Ложь;
				Результат.Вставить(Пара.Ключ, Пара.Значение);
			КонецЕсли;
		КонецЦикла;
		
		Возврат Результат;
	КонецФункции 
	
	Функция ЗафиксироватьИзменения(Обновления) Экспорт
		Для Каждого Пара Из Обновления Цикл
			ДанныеРасширения = Пара.Значение;
			
			ОбъектРасширения = А1Э_Объекты.Получить("Справочник.А1Обновление_Расширения", ДанныеРасширения.Ссылка);  
			
			Если ДанныеРасширения.Существует = Ложь Тогда
				ОбъектРасширения.Удалить();
				Сообщить("Зарегистрировано удаление расширения " + ДанныеРасширения.Имя);
				Продолжить;
			КонецЕсли;
			
			ЗаполнитьЗначенияСвойств(ОбъектРасширения, ДанныеРасширения);
			ОбъектРасширения.Наименование = ДанныеРасширения.Имя;
			
			ОбъектРасширения.Записать();
			Если НЕ ЗначениеЗаполнено(ДанныеРасширения.Ссылка) Тогда
				Сообщить("Зафиксировано добавление расширения " + ДанныеРасширения.Имя + " версии " + ДанныеРасширения.Версия);
			ИначеЕсли ДанныеРасширения.Версия <> ДанныеРасширения.СтараяВерсия Тогда
				Сообщить("Зафиксировано обновление расширения " + ДанныеРасширения.Имя + " с версии " + ДанныеРасширения.СтараяВерсия + " на версию " + ДанныеРасширения.Версия);
			КонецЕсли;
		КонецЦикла
	КонецФункции 
	
#КонецЕсли

#КонецОбласти

#Область Служебно

Функция НовыйДанныеРасширения() 
	Возврат Новый Структура("Ссылка,Имя,Версия,ХешСумма,СтараяВерсия,СтараяХешСумма,Существует");
КонецФункции

#КонецОбласти 

Функция ИмяМодуля() Экспорт
	Возврат "А1Обновление_Расширения";
КонецФункции 
